import 'package:shoplancer_vendor/features/rental_module/chat/domain/repositories/taxi_chat_repository_interface.dart';
import 'package:shoplancer_vendor/features/rental_module/chat/domain/services/taxi_chat_service_interface.dart';

class TaxiChatService implements TaxiChatServiceInterface {
  final TaxiChatRepositoryInterface chatRepositoryInterface;
  TaxiChatService({required this.chatRepositoryInterface});

}