import 'package:shoplancer_vendor/features/rental_module/banner/domain/repositories/taxi_banner_repository_interface.dart';
import 'package:shoplancer_vendor/features/rental_module/banner/domain/services/taxi_banner_service_interface.dart';

class TaxiBannerService implements TaxiBannerServiceInterface {
  final TaxiBannerRepositoryInterface taxiBannerRepositoryInterface;
  TaxiBannerService({required this.taxiBannerRepositoryInterface});

}