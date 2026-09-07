"""
Loads the model trained in WeatherGPT_NLU_Training.ipynb and exposes parse(text).
Expects the exported folder (model.pt, tokenizer files, label_maps.json) — download
it from Colab's Section 9 and place it wherever NLU_EXPORT_DIR points.
"""

import json
import os

import torch
from transformers import AutoModel, AutoTokenizer

NLU_EXPORT_DIR = os.environ.get("WEATHERGPT_NLU_EXPORT_DIR", "weathergpt_nlu_export")
MAX_LEN = 32


class JointIntentSlotModel(torch.nn.Module):
    """Must exactly mirror the architecture defined in the training notebook —
    if you change one, change both, or `load_state_dict` will fail or silently
    load into the wrong-shaped layers."""

    def __init__(self, model_name, num_intents, num_slots, dropout=0.1):
        super().__init__()
        self.bert = AutoModel.from_pretrained(model_name)
        hidden_size = self.bert.config.hidden_size
        self.dropout = torch.nn.Dropout(dropout)
        self.intent_classifier = torch.nn.Linear(hidden_size, num_intents)
        self.slot_classifier = torch.nn.Linear(hidden_size, num_slots)

    def forward(self, input_ids, attention_mask):
        outputs = self.bert(input_ids=input_ids, attention_mask=attention_mask)
        sequence_output = outputs.last_hidden_state
        pooled_output = sequence_output[:, 0, :]
        intent_logits = self.intent_classifier(self.dropout(pooled_output))
        slot_logits = self.slot_classifier(self.dropout(sequence_output))
        return intent_logits, slot_logits


class NluEngine:
    def __init__(self, export_dir: str = NLU_EXPORT_DIR):
        with open(os.path.join(export_dir, "label_maps.json")) as f:
            label_maps = json.load(f)
        self.intents = label_maps["intents"]
        self.slot_labels = label_maps["slot_labels"]
        self.model_name = label_maps["model_name"]

        self.tokenizer = AutoTokenizer.from_pretrained(export_dir)
        self.model = JointIntentSlotModel(self.model_name, len(self.intents), len(self.slot_labels))
        self.model.load_state_dict(torch.load(os.path.join(export_dir, "model.pt"), map_location="cpu"))
        self.model.eval()

    def parse(self, text: str) -> dict:
        words = text.strip().split()
        if not words:
            return {"intent": "out_of_scope", "confidence": 1.0, "location": None, "datetime": None, "attribute": None}

        encoding = self.tokenizer(
            words, is_split_into_words=True, truncation=True,
            max_length=MAX_LEN, padding="max_length", return_tensors="pt",
        )
        word_ids = encoding.word_ids()

        with torch.no_grad():
            intent_logits, slot_logits = self.model(encoding["input_ids"], encoding["attention_mask"])

        intent = self.intents[intent_logits.argmax(-1).item()]
        confidence = torch.softmax(intent_logits, -1).max().item()

        slot_preds = slot_logits.argmax(-1)[0].numpy()
        slots, current_type, current_words = {}, None, []

        def flush():
            if current_type and current_words:
                slots.setdefault(current_type, []).append(" ".join(current_words))

        prev_word_id = None
        for i, word_id in enumerate(word_ids):
            if word_id is None or word_id == prev_word_id:
                continue
            label = self.slot_labels[slot_preds[i]]
            if label.startswith("B-"):
                flush()
                current_type, current_words = label[2:], [words[word_id]]
            elif label.startswith("I-") and current_type == label[2:]:
                current_words.append(words[word_id])
            else:
                flush()
                current_type, current_words = None, []
            prev_word_id = word_id
        flush()

        return {
            "intent": intent,
            "confidence": round(confidence, 3),
            "location": slots.get("LOC", [None])[0],
            "datetime": slots.get("DATETIME", [None])[0],
            "attribute": slots.get("ATTR", [None])[0],
        }
