class IntentRouterService:

    async def route(self, nlu_result: dict) -> str:

        intent = nlu_result.get("intent", "unknown")
        domain = nlu_result.get("domain", "general")

        # =====================================
        # DOMAIN-SPECIFIC ROUTING
        # Domain routes get highest priority
        # =====================================

        domain_routes = {

            "farmer": "farmer_advisory",

            "aviation": "aviation_advisory",

            "marine": "marine_advisory",

            "outdoor": "outdoor_advisory"

        }

        if domain in domain_routes:
            return domain_routes[domain]


        # =====================================
        # INTENT-BASED ROUTING
        # =====================================

        intent_routes = {

            "current_weather": "weather",
            "forecast": "forecast",
            "weather_alert": "alert",
            "farmer_advisory": "farmer_advisory",
            "general_weather_query": "general"

        }

        return intent_routes.get(intent, "general")


intent_router_service = IntentRouterService()