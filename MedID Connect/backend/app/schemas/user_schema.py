from pydantic import BaseModel, ConfigDict, EmailStr, Field


class EmergencyContactBase(BaseModel):
    name: str = Field(min_length=2, max_length=160)
    relationship: str | None = None
    phone: str = Field(min_length=5, max_length=40)
    email: EmailStr | None = None


class EmergencyContactCreate(EmergencyContactBase):
    pass


class EmergencyContactRead(EmergencyContactBase):
    id: int
    model_config = ConfigDict(from_attributes=True)


class UserRead(BaseModel):
    id: int
    full_name: str
    email: EmailStr
    age: int | None = None
    gender: str | None = None
    blood_group: str | None = None
    phone: str | None = None
    emergency_contacts: list[EmergencyContactRead] = []

    model_config = ConfigDict(from_attributes=True)


class UserUpdate(BaseModel):
    full_name: str | None = Field(default=None, min_length=2, max_length=160)
    age: int | None = Field(default=None, ge=0, le=130)
    gender: str | None = None
    blood_group: str | None = None
    phone: str | None = None
    emergency_contact: EmergencyContactCreate | None = None
