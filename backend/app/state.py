from typing import Optional, Any


class AppState:

    def __init__(self):

        # NLU model
        self.nlu_engine:Any | None = None

        # Future RAG engine
        self.rag_service:Any | None = None

        # Future vision engine
        self.vision_engine:Any | None = None


app_state = AppState()