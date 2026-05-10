// Both backends run on the same EC2 instance:
//   - Spring Boot (apiHost): port 8080
//   - Python RAG  (ragHost): port 8000
// Switch to localhost branches when running services on your laptop.

const _ec2Host = '13.51.158.100';

String get apiHost => '$_ec2Host:8080';
// Local dev:
// String get apiHost {
//   if (kIsWeb) return 'localhost:8080';
//   if (defaultTargetPlatform == TargetPlatform.android) return '10.0.2.2:8080';
//   return 'localhost:8080';
// }

String get ragHost => '$_ec2Host:8000';
// Local dev:
// String get ragHost {
//   if (kIsWeb) return 'localhost:8000';
//   if (defaultTargetPlatform == TargetPlatform.android) return '10.0.2.2:8000';
//   return 'localhost:8000';
// }
