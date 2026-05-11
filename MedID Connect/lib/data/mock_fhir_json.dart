class MockFhirJson {
  static const Map<String, dynamic> bundle = {
    'resourceType': 'Bundle',
    'type': 'collection',
    'id': 'medid-connect-demo-bundle',
    'entry': [
      {
        'resource': {
          'resourceType': 'Patient',
          'id': 'pat-1001',
          'name': [
            {
              'use': 'official',
              'text': 'Aarav Mehta',
              'family': 'Mehta',
              'given': ['Aarav']
            }
          ],
          'gender': 'male',
          'birthDate': '1991-08-22',
          'telecom': [
            {'system': 'phone', 'value': '+91 98765 43210'},
            {'system': 'email', 'value': 'aarav.mehta@example.com'}
          ],
          'address': [
            {'text': 'Bandra West, Mumbai, Maharashtra'}
          ],
          'extension': [
            {
              'url':
                  'https://medidconnect.app/fhir/StructureDefinition/blood-group',
              'valueString': 'O+'
            },
            {
              'url':
                  'https://medidconnect.app/fhir/StructureDefinition/health-score',
              'valueInteger': 88
            }
          ],
        },
      },
      {
        'resource': {
          'resourceType': 'AllergyIntolerance',
          'id': 'alg-101',
          'clinicalStatus': {'text': 'active'},
          'criticality': 'high',
          'code': {'text': 'Penicillin'},
          'reaction': [
            {
              'manifestation': [
                {'text': 'Hives and facial swelling'}
              ]
            }
          ],
          'recordedDate': '2021-04-12'
        },
      },
      {
        'resource': {
          'resourceType': 'AllergyIntolerance',
          'id': 'alg-102',
          'clinicalStatus': {'text': 'active'},
          'criticality': 'moderate',
          'code': {'text': 'Peanuts'},
          'reaction': [
            {
              'manifestation': [
                {'text': 'Throat irritation'}
              ]
            }
          ],
          'recordedDate': '2022-10-04'
        },
      },
      {
        'resource': {
          'resourceType': 'Condition',
          'id': 'con-201',
          'clinicalStatus': {'text': 'active'},
          'verificationStatus': {'text': 'confirmed'},
          'severity': {'text': 'mild'},
          'code': {'text': 'Mild hypertension'},
          'onsetDateTime': '2023-03-08',
          'note': [
            {'text': 'Controlled with medication and low-sodium diet.'}
          ]
        },
      },
      {
        'resource': {
          'resourceType': 'Condition',
          'id': 'con-202',
          'clinicalStatus': {'text': 'active'},
          'verificationStatus': {'text': 'confirmed'},
          'severity': {'text': 'mild'},
          'code': {'text': 'Seasonal allergic rhinitis'},
          'onsetDateTime': '2019-07-14',
          'note': [
            {'text': 'Usually flares during monsoon season.'}
          ]
        },
      },
      {
        'resource': {
          'resourceType': 'MedicationRequest',
          'id': 'med-301',
          'status': 'active',
          'intent': 'order',
          'medicationCodeableConcept': {'text': 'Amlodipine 5 mg'},
          'authoredOn': '2023-03-12',
          'requester': {'display': 'Dr. Kavya Rao'},
          'dosageInstruction': [
            {
              'text': 'Take one tablet after breakfast',
              'timing': {
                'repeat': {'frequency': 1, 'period': 1, 'periodUnit': 'd'}
              }
            }
          ]
        },
      },
      {
        'resource': {
          'resourceType': 'MedicationRequest',
          'id': 'med-302',
          'status': 'active',
          'intent': 'order',
          'medicationCodeableConcept': {'text': 'Cetirizine 10 mg'},
          'authoredOn': '2024-06-05',
          'requester': {'display': 'Dr. Anil Shah'},
          'dosageInstruction': [
            {'text': 'Take one tablet at night when symptoms appear'}
          ]
        },
      },
      {
        'resource': {
          'resourceType': 'Observation',
          'id': 'obs-401',
          'status': 'final',
          'code': {
            'coding': [
              {'code': '8480-6', 'display': 'Systolic blood pressure'}
            ],
            'text': 'Systolic blood pressure'
          },
          'valueQuantity': {'value': 116, 'unit': 'mmHg'},
          'effectiveDateTime': '2026-04-22'
        },
      },
      {
        'resource': {
          'resourceType': 'DiagnosticReport',
          'id': 'dr-501',
          'status': 'final',
          'category': [
            {'text': 'Laboratory'}
          ],
          'code': {'text': 'Annual wellness panel'},
          'issued': '2026-04-20',
          'performer': [
            {'display': 'Apollo Diagnostics'}
          ],
          'conclusion':
              'Metabolic markers are stable. Lipids and glucose are in range.'
        },
      },
      {
        'resource': {
          'resourceType': 'Immunization',
          'id': 'imm-601',
          'status': 'completed',
          'vaccineCode': {'text': 'Influenza quadrivalent'},
          'occurrenceDateTime': '2025-11-08',
          'performer': [
            {
              'actor': {'display': 'City Care Clinic'}
            }
          ],
          'lotNumber': 'FLU-25-MH-771'
        },
      }
    ],
  };
}
