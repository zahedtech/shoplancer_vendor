import 'package:shoplancer_vendor/features/rental_module/profile/domain/repositories/taxi_profile_repository_interface.dart';
import 'package:shoplancer_vendor/features/rental_module/profile/domain/services/taxi_profile_service_interface.dart';

class TaxiProfileService implements TaxiProfileServiceInterface {
  final TaxiProfileRepositoryInterface taxiProfileRepositoryInterface;
  TaxiProfileService({required this.taxiProfileRepositoryInterface});
}
