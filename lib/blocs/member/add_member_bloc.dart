import 'package:flutter_bloc/flutter_bloc.dart';
import 'add_member_event.dart';
import 'add_member_state.dart';
import 'package:build_wise/services/user_service.dart';
import 'package:build_wise/models/user_model.dart';

class AddMemberBloc extends Bloc<AddMemberEvent, AddMemberState> {
  final UserService _userService;

  AddMemberBloc(this._userService) : super(const AddMemberState()) {
    on<CheckCEP>(_onCheckCEP);
    on<AddMemberSubmit>(_onAddMemberSubmit);
  }

  // Verificação do CEP e preenchimento automático dos campos de endereço
  Future<void> _onCheckCEP(CheckCEP event, Emitter<AddMemberState> emit) async {
    emit(state.copyWith(isLoading: true));

    try {
      final addressData = await _userService.verifyCEP(event.cep);

      emit(state.copyWith(
        isLoading: false,
        cepValid: true,
        address: addressData['rua'] ?? '',
        bairro: addressData['bairro'] ?? '',
        logradouro: addressData['logradouro'] ?? '',
        cidade: addressData['cidade'] ?? '',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        cepValid: false,
        errorMessage: 'CEP inválido',
      ));
    }
  }

  // Função para adicionar o membro (cliente ou funcionário)
  Future<void> _onAddMemberSubmit(
      AddMemberSubmit event, Emitter<AddMemberState> emit) async {
    emit(state.copyWith(isLoading: true));

    try {
      if (event.email.isEmpty ||
          event.password.isEmpty ||
          event.name.isEmpty ||
          event.lastName.isEmpty) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Todos os campos são obrigatórios',
        ));
        return;
      }

      // Cria uma instância de UserModel com os dados fornecidos
      final newUser = UserModel(
        id: '',
        email: event.email,
        name: event.name,
        lastName: event.lastName,
        cep: event.cep,
        role: event.role,
        architectId: event.architectId,
        address: state.address,
        bairro: state.bairro,
        logradouro: state.logradouro,
        cidade: state.cidade,
        numero: event.numero,
        projectIds: event.projectIds ?? [],
        password: event.password,
      );

      // Criação do usuário com o UserModel
      final generatedUserId = await _userService.createUser(newUser);

      // Atualização no documento do projeto com base no role
      if (event.projectIds != null) {
        for (String projectId in event.projectIds!) {
          if (event.role == 'employee') {
            await _userService.updateProjectEmployees(
                projectId, generatedUserId);
          } else if (event.role == 'client') {
            await _userService.updateProjectClients(projectId, generatedUserId);
          }
        }
      }

      // Indicando que a operação foi bem-sucedida
      emit(state.copyWith(
        isLoading: false,
        isSuccess: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao criar usuário',
      ));
    }
  }
}
