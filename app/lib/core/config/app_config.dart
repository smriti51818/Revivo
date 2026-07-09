/// Runtime configuration for the live AWS backend.
///
/// Values come from the deployed CDK stacks (Revivo-Auth / Revivo-Api outputs).
/// Flip [useLiveApi] to false to run entirely on in-memory mock repositories
/// (offline demo, no network) — the UI is identical either way.
class AppConfig {
  const AppConfig({
    required this.region,
    required this.userPoolId,
    required this.userPoolClientId,
    required this.apiBaseUrl,
    required this.useLiveApi,
  });

  final String region;
  final String userPoolId;
  final String userPoolClientId;

  /// API Gateway base URL, without a trailing slash.
  final String apiBaseUrl;

  final bool useLiveApi;

  /// Cognito Identity Provider endpoint for this region.
  String get cognitoIdpUrl => 'https://cognito-idp.$region.amazonaws.com/';

  /// Live pilot configuration (ap-south-1).
  static const AppConfig current = AppConfig(
    region: 'ap-south-1',
    userPoolId: 'ap-south-1_4GFtB35OS',
    userPoolClientId: '4hi9r9pue4h1qpeuc9enp60553',
    apiBaseUrl: 'https://j5aq1g1vbd.execute-api.ap-south-1.amazonaws.com/prod',
    // Live for the submission: real Cognito login + Bedrock/Rekognition/Step
    // Functions all fire. Flip to false for a fully offline demo on mock data.
    useLiveApi: true,
  );
}
