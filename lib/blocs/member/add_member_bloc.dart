import 'package:flutter_bloc/flutter_bloc.dart';
import 'add_member_event.dart';
import 'add_member_state.dart';
import 'package:build_wise/services/user_service.dart';

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

      // Criação do usuário e salvamento no Firebase
      await _userService.createUser(
        email: event.email,
        password: event.password,
        name: event.name,
        lastName: event.lastName,
        cep: event.cep, // Garantindo que o CEP não seja nulo
        isClient: event.isClient,
        projectIds: event
            .projectIds, // Modificado para aceitar lista de IDs de projetos
        address: state.address, // Salvando o endereço preenchido
        bairro: state.bairro, // Salvando o bairro preenchido
        logradouro: state.logradouro, // Salvando o logradouro preenchido
        cidade: state.cidade, // Salvando a cidade preenchida
        numero: event.numero, // Salvando o número preenchido
      );

      // Indicando que a operação foi bem-sucedida
      emit(state.copyWith(
        isLoading: false,
        isSuccess: true, // Indicando sucesso da operação
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao criar usuário',
      ));
    }
  }
}
