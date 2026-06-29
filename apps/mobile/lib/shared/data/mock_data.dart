import '../../features/clinics/models/clinic.dart';
import '../../features/clinics/models/doctor.dart';
import '../../features/pets/domain/pet.dart';
import '../../features/visit_records/domain/visit_document.dart';
import '../../features/visit_records/domain/visit_record.dart';

class MockData {
  static final pets = <Pet>[
    Pet(
      id: 'mock_pet_luna',
      name: 'Luna',
      species: 'dog',
      breed: 'Corgi',
      sex: 'female',
      birthDate: DateTime(2022, 4, 12),
      weightKg: 11.8,
      color: 'Sable',
      microchipNumber: '990000000001',
      notes: 'Sensitive stomach. Prefers calm handling.',
    ),
    Pet(
      id: 'mock_pet_milo',
      name: 'Milo',
      species: 'cat',
      breed: 'British Shorthair',
      sex: 'male',
      birthDate: DateTime(2020, 9, 5),
      weightKg: 6.2,
      color: 'Blue gray',
      notes: 'Indoor cat. Annual vaccination due soon.',
    ),
  ];

  static const clinics = [
    Clinic(id: 'mock_clinic_1', name: 'North Star Vet Clinic', address: 'Central Avenue 12', status: 'Published'),
    Clinic(id: 'mock_clinic_2', name: 'Green Paw Veterinary', address: 'Garden Street 4', status: 'Published'),
  ];

  static const doctors = [
    Doctor(id: 'mock_doctor_1', fullName: 'Dr. Anna Kovalenko', specialization: 'General care', clinicName: 'North Star Vet Clinic'),
    Doctor(id: 'mock_doctor_2', fullName: 'Dr. Max Levin', specialization: 'Diagnostics', clinicName: 'Green Paw Veterinary'),
  ];

  static final visitRecords = <VisitRecord>[
    VisitRecord(
      id: 'mock_visit_1',
      petId: 'mock_pet_luna',
      visitDate: DateTime.now().subtract(const Duration(days: 18)),
      clinicName: 'North Star Vet Clinic',
      doctorName: 'Dr. Anna Kovalenko',
      reason: 'Preventive checkup',
      diagnosis: 'No acute issues found.',
      treatmentNotes: 'General examination completed. Temperature and weight are normal.',
      recommendations: 'Review vaccination plan next month.',
      followUpAt: DateTime.now().add(const Duration(days: 32)),
      documentCount: 1,
    ),
    VisitRecord(
      id: 'mock_visit_2',
      petId: 'mock_pet_luna',
      visitDate: DateTime.now().subtract(const Duration(days: 96)),
      clinicName: 'Green Paw Veterinary',
      doctorName: 'Dr. Max Levin',
      reason: 'Digestive discomfort',
      diagnosis: 'Mild dietary intolerance.',
      treatmentNotes: 'Diet adjusted. No medication required.',
      recommendations: 'Avoid sudden food changes.',
      documentCount: 1,
    ),
    VisitRecord(
      id: 'mock_visit_3',
      petId: 'mock_pet_milo',
      visitDate: DateTime.now().subtract(const Duration(days: 42)),
      clinicName: 'North Star Vet Clinic',
      doctorName: 'Dr. Anna Kovalenko',
      reason: 'Vaccination',
      diagnosis: 'Routine vaccination completed.',
      treatmentNotes: 'No adverse reaction observed.',
      recommendations: 'Next routine check in 12 months.',
    ),
  ];

  static final documents = <VisitDocument>[
    VisitDocument(
      id: 'mock_doc_1',
      visitRecordId: 'mock_visit_1',
      petId: 'mock_pet_luna',
      title: 'Vaccination recommendation',
      type: 'recommendation',
      createdAt: DateTime.now().subtract(const Duration(days: 18)),
    ),
    VisitDocument(
      id: 'mock_doc_2',
      visitRecordId: 'mock_visit_2',
      petId: 'mock_pet_luna',
      title: 'Diet plan',
      type: 'certificate',
      createdAt: DateTime.now().subtract(const Duration(days: 96)),
    ),
  ];
}

