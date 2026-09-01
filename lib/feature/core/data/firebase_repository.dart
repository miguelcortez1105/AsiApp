import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../home/home_page.dart';
import '../../mngmt/gestao_de_pessoas.dart';
import '../../perfil/perfil_screen.dart';

class FirebaseRepository {
  FirebaseRepository._();

  static final instance = FirebaseRepository._();
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Stream<List<Project>> watchProjects() => _firestore
      .collection('projects')
      .orderBy('name')
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Project.fromFirestore).toList());

  Stream<List<PersonRecord>> watchPeople() => _firestore
      .collection('users')
      .orderBy('name')
      .snapshots()
      .map((snapshot) => snapshot.docs.map(PersonRecord.fromFirestore).toList());

  Future<void> saveProfile(UserProfile profile) => _firestore
      .collection('users')
      .doc(profile.uid)
      .set(profile.toFirestore(), SetOptions(merge: true));

  Future<UserProfile?> getProfile(String uid) async {
    final document = await _firestore.collection('users').doc(uid).get();
    return document.exists ? UserProfile.fromFirestore(document) : null;
  }

  Future<void> savePerson(PersonRecord person) => _firestore
      .collection('users')
      .doc(person.uid)
      .set(person.toFirestore(), SetOptions(merge: true));

  Future<String> uploadProfileImage({
    required String uid,
    required Uint8List bytes,
    required String extension,
  }) async {
    final reference = _storage.ref('profile_images/$uid.$extension');
    await reference.putData(bytes, SettableMetadata(contentType: 'image/$extension'));
    return reference.getDownloadURL();
  }
}

class Hierarchy {
  Hierarchy._();

  static const awaitingRoleAssignment = 'Aguardando atribuição';
  static const administrator = 'Administrador';
  static const presidency = 'Presidência';
  static const vicePresidency = 'Vice-Presidência';
  static const directory = 'Diretoria';
  static const management = 'Gerência';
  static const member = 'Membro';
  static const developer = 'Desenvolvedor';

  static const roles = [
    administrator,
    presidency,
    vicePresidency,
    directory,
    management,
    member,
  ];

  static const _levels = {
    awaitingRoleAssignment: 0,
    member: 1,
    management: 2,
    vicePresidency: 3,
    directory: 4,
    presidency: 5,
    administrator: 6,
    developer: 6,
  };

  static bool isAwaitingRoleAssignment(String role) =>
      role.trim() == awaitingRoleAssignment;

  static bool canManagePeople(String role) => level(role) >= level(management);
  static bool canViewFinance(String role) => level(role) >= level(directory);
  static bool canManageAll(String role) => level(role) >= level(administrator);
  static bool canAssignRole(String role) =>
      role.trim() == presidency || role.trim() == vicePresidency;
  static int level(String role) => _levels[role.trim()] ?? 0;
}

