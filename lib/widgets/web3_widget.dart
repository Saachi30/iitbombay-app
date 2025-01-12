// // lib/widgets/web3_widgets.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/web3_provider.dart';
// import '../services/auth_service.dart';

// class Web3ActionsWidget extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final web3 = Provider.of<Web3Provider>(context);
//     final auth = Provider.of<AuthService>(context);

//     return Column(
//       children: [
//         // Hidden WebView
//         web3.web3Service.buildHiddenWebView(),

//         // Wallet Connection
//         if (web3.connectedAddress == null)
//           ElevatedButton(
//             onPressed: web3.isConnecting
//                 ? null
//                 : () async {
//                     try {
//                       await web3.connectWallet();
//                       if (web3.connectedAddress != null) {
//                         await auth.updateWalletAddress(web3.connectedAddress!);
//                       }
//                     } catch (e) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text(e.toString())),
//                       );
//                     }
//                   },
//             child: web3.isConnecting
//                 ? CircularProgressIndicator()
//                 : Text('Connect Wallet'),
//           ),

//         // NFT Upload
//         ElevatedButton(
//           onPressed: web3.isProcessing
//               ? null
//               : () async {
//                   try {
//                     await web3.uploadNFT(
//                       'ipfsHash',
//                       'metadata',
//                       'encryptedKey',
//                     );
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('NFT uploaded successfully')),
//                     );
//                   } catch (e) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text(e.toString())),
//                     );
//                   }
//                 },
//           child: web3.isProcessing
//               ? CircularProgressIndicator()
//               : Text('Upload NFT'),
//         ),

//         // Grant Access
//         ElevatedButton(
//           onPressed: web3.isProcessing
//               ? null
//               : () async {
//                   try {
//                     await web3.grantAccess(
//                       'ipfsHash',
//                       'recipientAddress',
//                       86400, // 24 hours
//                     );
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('Access granted successfully')),
//                     );
//                   } catch (e) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text(e.toString())),
//                     );
//                   }
//                 },
//           child: web3.isProcessing
//               ? CircularProgressIndicator()
//               : Text('Grant Access'),
//         ),

//         // Other action buttons...
//       ],
//     );
//   }
// }

// class NFTListWidget extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final web3 = Provider.of<Web3Provider>(context);

//     return ListView.builder(
//       itemCount: web3.userNFTs.length,
//       itemBuilder: (context, index) {
//         final nft = web3.userNFTs[index];
//         return ListTile(
//           title: Text('Token ID: ${nft.tokenId}'),
//           subtitle: Text('IPFS Hash: ${nft.ipfsHash}'),
//           trailing: PopupMenuButton(
//             itemBuilder: (context) => [
//               PopupMenuItem(
//                 child: Text('Transfer'),
//                 onTap: () => _showTransferDialog(context, web3, nft),
//               ),
//               PopupMenuItem(
//                 child: Text('Burn'),
//                 onTap: () => _showBurnConfirmation(context, web3, nft),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   void _showTransferDialog(BuildContext context, Web3Provider web3, NFTData nft) {
//     final recipientController = TextEditingController();

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Transfer NFT'),
//         content: TextField(// Continuing lib/widgets/web3_widgets.dart

//           controller: recipientController,
//           decoration: InputDecoration(
//             labelText: 'Recipient Address',
//             hintText: '0x...',
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               try {
//                 await web3.transferNFT(
//                   recipientController.text,
//                   nft.tokenId,
//                 );
//                 Navigator.pop(context);
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text('NFT transferred successfully')),
//                 );
//               } catch (e) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text(e.toString())),
//                 );
//               }
//             },
//             child: Text('Transfer'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showBurnConfirmation(BuildContext context, Web3Provider web3, NFTData nft) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Burn NFT'),
//         content: Text('Are you sure you want to burn this NFT? This action cannot be undone.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel'),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               foregroundColor: Colors.white,
//             ),
//             onPressed: () async {
//               try {
//                 await web3.burnNFT(nft.tokenId);
//                 Navigator.pop(context);
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text('NFT burned successfully')),
//                 );
//               } catch (e) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text(e.toString())),
//                 );
//               }
//             },
//             child: Text('Burn'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class AccessControlWidget extends StatelessWidget {
//   final String ipfsHash;

//   const AccessControlWidget({Key? key, required this.ipfsHash}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final web3 = Provider.of<Web3Provider>(context);

//     return Card(
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Access Control',
//               style: Theme.of(context).textTheme.titleLarge,
//             ),
//             SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: () => _showGrantAccessDialog(context, web3),
//               child: Text('Grant Access'),
//             ),
//             SizedBox(height: 8),
//             ElevatedButton(
//               onPressed: () => _showRevokeAccessDialog(context, web3),
//               child: Text('Revoke Access'),
//             ),
//             SwitchListTile(
//               title: Text('Universal Access'),
//               value: false, // You should store this state
//               onChanged: (value) async {
//                 try {
//                   await web3.setUniversalAccess(ipfsHash, value);
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Universal access updated')),
//                   );
//                 } catch (e) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text(e.toString())),
//                   );
//                 }
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showGrantAccessDialog(BuildContext context, Web3Provider web3) {
//     final recipientController = TextEditingController();
//     final durationController = TextEditingController();

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Grant Access'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(
//               controller: recipientController,
//               decoration: InputDecoration(
//                 labelText: 'Recipient Address',
//                 hintText: '0x...',
//               ),
//             ),
//             SizedBox(height: 8),
//             TextField(
//               controller: durationController,
//               decoration: InputDecoration(
//                 labelText: 'Duration (in hours)',
//                 hintText: '24',
//               ),
//               keyboardType: TextInputType.number,
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               try {
//                 final duration = int.parse(durationController.text) * 3600;
//                 await web3.grantAccess(
//                   ipfsHash,
//                   recipientController.text,
//                   duration,
//                 );
//                 Navigator.pop(context);
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text('Access granted successfully')),
//                 );
//               } catch (e) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text(e.toString())),
//                 );
//               }
//             },
//             child: Text('Grant'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showRevokeAccessDialog(BuildContext context, Web3Provider web3) {
//     final recipientController = TextEditingController();

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Revoke Access'),
//         content: TextField(
//           controller: recipientController,
//           decoration: InputDecoration(
//             labelText: 'Recipient Address',
//             hintText: '0x...',
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               try {
//                 await web3.revokeAccess(
//                   ipfsHash,
//                   recipientController.text,
//                 );
//                 Navigator.pop(context);
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text('Access revoked successfully')),
//                 );
//               } catch (e) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text(e.toString())),
//                 );
//               }
//             },
//             child: Text('Revoke'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Example of how to use these widgets in a screen
// class NFTManagementScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('NFT Management'),
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Web3ActionsWidget(),
//               SizedBox(height: 16),
//               Container(
//                 height: 300,
//                 child: NFTListWidget(),
//               ),
//               SizedBox(height: 16),
//               AccessControlWidget(ipfsHash: 'your-ipfs-hash'),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }