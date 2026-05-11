class AbdmSandboxService:
    """ABDM/ABHA sandbox placeholder.

    Real ABDM integration requires sandbox onboarding, client ID/secret,
    gateway registration, HIP/HIU role approval, Consent Manager flows,
    callback URL verification, and production certification. This service only
    defines safe placeholder contracts for future implementation.
    """

    def create_abha_address_placeholder(self, mobile: str) -> dict[str, str]:
        return {"status": "placeholder", "abha_address": f"demo-{mobile[-4:]}@abdm", "next_step": "verify_mobile_otp"}

    def verify_mobile_otp_placeholder(self, transaction_id: str, otp: str) -> dict[str, str]:
        return {"status": "verified_placeholder", "transaction_id": transaction_id, "otp_received": "***"}

    def link_health_record_placeholder(self, abha_address: str) -> dict[str, str]:
        return {"status": "link_requested_placeholder", "abha_address": abha_address}

    def request_consent_placeholder(self, abha_address: str, purpose: str) -> dict[str, str]:
        return {"status": "consent_requested_placeholder", "abha_address": abha_address, "purpose": purpose}

    def fetch_health_information_placeholder(self, consent_id: str) -> dict:
        return {
            "status": "sandbox_ready_placeholder",
            "consent_id": consent_id,
            "bundle": {"resourceType": "Bundle", "type": "collection", "entry": []},
        }
