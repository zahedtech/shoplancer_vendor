import 'package:shoplancer_vendor/interface/repository_interface.dart';

abstract class CampaignRepositoryInterface implements RepositoryInterface {
  Future<dynamic> joinCampaign(int? campaignID);
  Future<dynamic> leaveCampaign(int? campaignID);
}