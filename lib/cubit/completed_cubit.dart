import 'package:bloc/bloc.dart';

part 'completed_state.dart';

class CompletedCubit extends Cubit<CompletedState> {
  CompletedCubit() : super(CompletedState());

  void completed(bool completed) => emit(CompletedState());
}
