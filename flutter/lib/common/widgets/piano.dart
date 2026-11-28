import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common.dart';
import '../../consts.dart';

/// Piano Free di CondividOS: 15 minuti al giorno di controllo, contati da server/conti.
/// Sui telefoni solo il contatore, mai inviti a pagare (App Store 3.1.3).

/// "Free · oggi 11 di 15 minuti" con una barra sottile; "Piano Pro" per i Pro.
/// Niente finché conti non ha risposto.
Widget pianoAccount(BuildContext context) => Obx(() {
      final u = gFFI.userModel;
      final small = Theme.of(context).textTheme.bodySmall;
      if (u.piano.value == 'pro') return Text(translate('Pro plan'), style: small);
      if (u.piano.value != 'free') return const SizedBox.shrink();
      final limite = u.minutiFree.value;
      final usati = (u.secondiUsati.value / 60).round().clamp(0, limite);
      final finiti = usati >= limite;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            translate('free-minutes-today')
                .replaceFirst('{}', '$usati')
                .replaceFirst('{}', '$limite'),
            style: small),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: limite > 0 ? usati / limite : 1,
            minHeight: 4,
            backgroundColor: Theme.of(context).dividerColor,
            color: finiti ? kColorWarn : Theme.of(context).colorScheme.primary,
          ),
        ),
      ]);
    });

/// Nella sessione: un avviso quando restano 2 minuti gratuiti oggi (a zero conti chiude).
/// Da cancellare alla fine della sessione.
Timer avvisoMinutiFree() {
  final u = gFFI.userModel;
  late final Timer timer;
  Future<void> controlla() async {
    if (!await u.aggiornaConto()) return; // senza rete si riprova
    if (u.piano.value != 'free') return timer.cancel();
    final resto = u.minutiFree.value * 60 - u.secondiUsati.value;
    if (resto > 120) return;
    timer.cancel();
    if (resto <= 0) return; // conti sta già chiudendo la sessione
    final min = (resto / 60).ceil();
    showToast(
        min >= 2
            ? translate('{$min} free minutes left today')
            : translate('Less than a minute of free time left today'),
        timeout: const Duration(seconds: 8),
        alignment: const Alignment(0, -0.8));
  }

  // ponytail: domanda a conti ogni 30 s; l'avviso arriva tra 2 e 1,5 minuti dalla fine
  timer = Timer.periodic(const Duration(seconds: 30), (_) => controlla());
  controlla();
  return timer;
}
