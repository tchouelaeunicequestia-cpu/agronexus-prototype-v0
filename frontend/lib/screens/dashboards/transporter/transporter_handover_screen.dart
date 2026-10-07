import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/auth_provider.dart';
import 'dart:ui';
import 'dart:async';

class TransporterHandoverScreen extends StatefulWidget {
  const TransporterHandoverScreen({super.key});

  @override
  State<TransporterHandoverScreen> createState() => _TransporterHandoverScreenState();
}

class _TransporterHandoverScreenState extends State<TransporterHandoverScreen> {
  static const _surface = Color(0xFF0b1326);
  static const _surfaceContainer = Color(0xFF171f33);
  static const _surfaceContainerHigh = Color(0xFF222a3d);
  static const _surfaceContainerLow = Color(0xFF131b2e);
  static const _primary = Color(0xFF4edea3);
  static const _tertiary = Color(0xFFffb95f);
  static const _secondary = Color(0xFF45dfa4);
  static const _onSurface = Color(0xFFdae2fd);
  static const _onSurfaceVariant = Color(0xFFbbcabf);

  final List<TextEditingController> _otpControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isReleasing = false;
  bool _isSettled = false;

  @override
  void initState() {
    super.initState();
    _otpControllers[0].text = '8';
    _otpControllers[1].text = '4';
    _otpControllers[2].text = '2';
  }

  @override
  void dispose() {
    for (var c in _otpControllers) { c.dispose(); }
    for (var n in _focusNodes) { n.dispose(); }
    super.dispose();
  }

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 3) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _handleReleaseEscrow() async {
    setState(() => _isReleasing = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) {
      setState(() {
        _isReleasing = false;
        _isSettled = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: _surface,
      appBar: _buildAppBar(user),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            _buildTerminalBanner(),
            const SizedBox(height: 16),
            _buildStage1(),
            const SizedBox(height: 16),
            _buildStage2(),
            const SizedBox(height: 16),
            _buildInspectionChecklist(),
            const SizedBox(height: 16),
            _buildSettlementPreview(),
            const SizedBox(height: 16),
            _buildActionCTA(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(dynamic user) {
    return AppBar(
      backgroundColor: const Color(0xFF060e20).withOpacity(0.85),
      elevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(color: Colors.transparent),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: _primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Color(0xFF003824), size: 18),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text(
                    'Handover',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _onSurface),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    user?.name ?? 'UNIT-740X',
                    style: const TextStyle(fontSize: 11, color: _onSurfaceVariant, fontFamily: 'Inter'),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text('•', style: TextStyle(fontSize: 10, color: Colors.white30)),
                  ),
                  const Text(
                    '42T SEMI',
                    style: TextStyle(fontSize: 11, color: _primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _surfaceContainerHigh.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.circle, color: _primary, size: 8),
              SizedBox(width: 4),
              Text('ONLINE', style: TextStyle(color: _primary, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none, color: _onSurfaceVariant),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildTerminalBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceContainerHigh.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: _primary.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, color: _primary, size: 6),
                          SizedBox(width: 6),
                          Text('ESCROW SECURE ENCLAVE', style: TextStyle(color: _primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('#WB-2026-098214', style: TextStyle(color: _onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Dual-Key Delivery Handover Terminal', style: TextStyle(color: _onSurface, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                const Text('Cryptographic escrow settlement protocol ISO-20022 compliant', style: TextStyle(color: _onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2d3449),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.verified_user, color: _primary, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildStage1() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(color: const Color(0xFF10b981), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.check, color: Color(0xFF00422b), size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text('Stage 1: Farm Gate Dispatch', style: TextStyle(color: _onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: const Text('VERIFIED', style: TextStyle(color: _primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _surfaceContainer, borderRadius: BorderRadius.circular(12)),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Origin Producer Signature', style: TextStyle(color: _onSurfaceVariant, fontSize: 11)),
                      SizedBox(height: 4),
                      Text('Eunice Françoise', style: TextStyle(color: _onSurface, fontSize: 12, fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text('07:30 UTC • Gate #04', style: TextStyle(color: _onSurfaceVariant, fontSize: 11)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _surfaceContainer, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Producer Auth Key', style: TextStyle(color: _onSurfaceVariant, fontSize: 11)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildAuthKeyBox('7'),
                          _buildAuthKeyBox('3'),
                          _buildAuthKeyBox('9'),
                          _buildAuthKeyBox('1'),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Row(
                        children: [
                          Icon(Icons.my_location, color: Color(0xFF68fcbf), size: 12),
                          SizedBox(width: 4),
                          Text('GPS ±1m Lock', style: TextStyle(color: Color(0xFF68fcbf), fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuthKeyBox(String val) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: const Color(0xFF2d3449), borderRadius: BorderRadius.circular(4)),
      child: Text(val, style: const TextStyle(color: _primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
    );
  }

  Widget _buildStage2() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFe29100).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: _tertiary, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    const Text('STAGE 2: BUYER OTP AUTHORIZATION', style: TextStyle(color: _tertiary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ],
                ),
                const Icon(Icons.pin, color: _tertiary, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warehouse, color: _primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Destination Terminal', style: TextStyle(color: _onSurfaceVariant, fontSize: 11)),
                    const Text('Bastos Wholesale Depot', style: TextStyle(color: _onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
                    const Text('Zone 3C, Yaoundé, Centre Region', style: TextStyle(color: _onSurfaceVariant, fontSize: 12)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.badge, color: _secondary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Designated Signer', style: TextStyle(color: _onSurfaceVariant, fontSize: 11)),
                              const Text('Marcelle Nana (Depot Manager)', style: TextStyle(color: _onSurface, fontSize: 14, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: _surfaceContainerHigh, borderRadius: BorderRadius.circular(20)),
                          child: const Row(
                            children: [
                              Icon(Icons.call, color: _primary, size: 16),
                              SizedBox(width: 4),
                              Text('Contact', style: TextStyle(color: _primary, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF060e20).withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('Receiver Dual-Key Code', style: TextStyle(color: _onSurface, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text.rich(
                  TextSpan(
                    text: 'Ask Marcelle Nana for the 4-digit token dispatched to her SMS terminal (',
                    style: TextStyle(color: _onSurfaceVariant, fontSize: 12),
                    children: [
                      TextSpan(text: '+237 694•••250', style: TextStyle(color: _onSurface, fontWeight: FontWeight.w500)),
                      TextSpan(text: ')'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 56,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, inset: true)],
                      ),
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _primary),
                        decoration: InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          hintText: index == 3 ? '•' : '',
                          hintStyle: TextStyle(color: _onSurfaceVariant.withOpacity(0.4)),
                        ),
                        onChanged: (value) => _onOtpChanged(value, index),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.qr_code_scanner, color: _tertiary, size: 20),
                    label: const Text('Or Scan Buyer Handover QR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _surfaceContainerHigh,
                      foregroundColor: _onSurface,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionChecklist() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Transporter Verification Gate', style: TextStyle(color: _onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
              Text('3 of 3 Confirmed', style: TextStyle(color: _primary, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _buildChecklistItem('Produce temperature within standard range', 'Telemetric probe: 4.3°C (Target: 3.5°C - 5.5°C)'),
          const SizedBox(height: 8),
          _buildChecklistItem('Crates & cargo security seals intact', 'Digital tamper-tag #TAG-982 matched & sealed'),
          const SizedBox(height: 8),
          _buildChecklistItem('Tare deduction & certified weighbridge', '12,480 kg Net Weight acknowledged by depot'),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(4)),
            child: const Icon(Icons.check, color: Color(0xFF003824), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: _onSurface, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: _onSurfaceVariant, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceContainerHigh.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: _tertiary, size: 20),
                  SizedBox(width: 8),
                  Text('Escrow Disbursement Direct-Sweep', style: TextStyle(color: _onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              Text('INSTANT SETTLE', style: TextStyle(color: _secondary, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF2d3449)),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Transporter Freight Fee', style: TextStyle(color: _onSurfaceVariant, fontSize: 12)),
              Text('185,000 FCFA', style: TextStyle(color: _onSurface, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('AgroNexus Platform Fee', style: TextStyle(color: _onSurfaceVariant, fontSize: 12)),
              Text('0 FCFA (Escrow Covered)', style: TextStyle(color: _primary, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Net Instant Payout', style: TextStyle(color: _onSurface, fontSize: 14, fontWeight: FontWeight.bold)),
                  Text('MTN MoMo (+237 677•••881)', style: TextStyle(color: _onSurfaceVariant, fontSize: 12)),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('185,000', style: TextStyle(color: _primary, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -1)),
                  const SizedBox(width: 4),
                  const Text('FCFA', style: TextStyle(color: _primary, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCTA() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSettled || _isReleasing ? null : _handleReleaseEscrow,
            icon: _isReleasing
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Color(0xFF003824), strokeWidth: 2))
                : Icon(_isSettled ? Icons.verified : Icons.lock_open, size: 24),
            label: Text(
              _isReleasing ? 'Clearing Multi-Sig Escrow...' : (_isSettled ? '185,000 FCFA Disbursed!' : 'Verify OTP & Release Escrow'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isSettled ? const Color(0xFF00bd85) : _primary,
              foregroundColor: _isSettled ? Colors.white : const Color(0xFF003824),
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              disabledBackgroundColor: _primary.withOpacity(0.5),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gavel, color: _primary, size: 14),
            SizedBox(width: 6),
            Text('Dual cryptographic keys unlock instantaneous escrow clearance', style: TextStyle(color: _onSurfaceVariant, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}
