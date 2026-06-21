// THROWAWAY SPIKE — Phase 11 GenUI/native-canvas kill-shot (Plan 11-02, Task 2).
//
// PURPOSE: the model client + A2UI transport that drives the spike's present_activity
// loop. Wires a Gemini Flash model (via Firebase AI Logic) into GenUI's A2UI streaming
// transport so the model can emit a `present_activity` component, which GenUI renders by
// hosting the real native StrokeCanvas (D-03/D-04). This is the streaming half of the
// seam Phase 14's GATE turns on.
//
// Verified against the INSTALLED genui 0.9.2 + firebase_ai 3.13.0 source (the docs
// version-drift — they still name the DEAD firebase_vertex_ai, Pitfall 5):
//   * model:     FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash', ...)
//                — NEVER FirebaseVertexAI / firebase_vertex_ai (dead).
//   * transport: A2uiTransportAdapter(onSend: ...) ; .addChunk(text) feeds LLM chunks
//                back into the A2UI parser ; Conversation wires controller <-> transport.
//   * stream:    model.generateContentStream([Content.text(...)]) -> per-chunk addChunk.
//   * prompt:    PromptBuilder.chat(catalog:).systemPromptJoined() + the present_activity
//                fragment, sent as Content.system to the model.
//
// TextPart naming: BOTH genui and firebase_ai export a `TextPart`. Per the genui
// integrate-genui-firebase skill, genui is imported with `hide TextPart` and re-imported
// as `genui` so the genui ChatMessage `TextPart` is reachable as `genui.TextPart`, while
// the bare `TextPart`/`Content` come from firebase_ai.
//
// SECURITY (T-11-03): the ONLY thing that crosses the network is the model's own
// present_activity text + the hardcoded letterId ("baa"). This transport sends NO
// List<Offset> stroke data and NO nickname/name/PII — the per-stroke pointer->paint loop
// stays entirely local (D-07). Model/transport errors are CAUGHT and surfaced as a
// visible "drop" finding (a failed call is GATE data, not a crash).
//
// App Check (D-13): unenforced in this throwaway scope. If the backend rejects the call
// for missing App Check, register the App Check DEBUG provider (RESEARCH A3) and record
// the fallback in the SUMMARY. This unenforced posture MUST NOT carry into Phase 14.
//
// This file edits no durable file; the SC-4 git-diff guard proves the sacred paths stay
// untouched for the whole spike.

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart' hide TextPart;
import 'package:genui/genui.dart' as genui;

import '../catalog/spike_catalog.dart';
import 'present_activity_tool.dart';

/// The Flash model the spike drives (D-12 — any Flash that supports the loop).
const String kSpikeModel = 'gemini-2.5-flash';

/// The first user turn that kicks the present_activity loop. It carries ONLY the
/// hardcoded letterId — never strokes, never PII (T-11-03).
const String kKickoffPrompt =
    'The child is ready to practise. Present the tracing activity for letterId '
    '"$kSpikeLetterId" now.';

/// Wires Gemini Flash into GenUI's A2UI transport and exposes a [start] that kicks
/// the present_activity loop. Mirrors auth_service.dart's degrade-gracefully posture:
/// a failed model/transport call surfaces via [onDrop] rather than throwing out.
class GeminiTransport {
  GeminiTransport({this.onDrop, this.onSurfaceAdded}) {
    _catalog = buildSpikeCatalog();

    // The model: Firebase AI Logic (Gemini Developer API) — googleAI(), NOT vertex.
    _model = FirebaseAI.googleAI().generativeModel(
      model: kSpikeModel,
      systemInstruction: Content.system(_systemInstruction()),
    );

    // GenUI surface controller over the spike catalog.
    _controller = SurfaceController(catalogs: <Catalog>[_catalog]);

    // A2UI transport: onSend converts a GenUI ChatMessage to a firebase_ai Content,
    // streams the model response, and feeds each chunk back via addChunk.
    _transport = A2uiTransportAdapter(onSend: _sendAndReceive);

    // The conversation ties controller <-> transport together.
    _conversation = Conversation(
      controller: _controller,
      transport: _transport,
    );

    _conversation.events.listen(_onEvent);
  }

  /// Called when the model/transport degrades — the visible "drop" finding (GATE data).
  final void Function(Object error)? onDrop;

  /// Called with each surfaceId GenUI adds, so the host can render a Surface for it.
  final void Function(String surfaceId)? onSurfaceAdded;

  late final Catalog _catalog;
  late final GenerativeModel _model;
  late final SurfaceController _controller;
  late final A2uiTransportAdapter _transport;
  late final Conversation _conversation;

  /// The surface controller — the host builds `Surface(surfaceContext: ...)` from it.
  SurfaceController get controller => _controller;

  /// Joins the GenUI system prompt (which advertises the catalog, incl. the custom
  /// present_activity item) with the present_activity behaviour fragment.
  String _systemInstruction() {
    final PromptBuilder builder = PromptBuilder.chat(catalog: _catalog);
    return <String>[
      builder.systemPromptJoined(),
      presentActivitySystemPromptFragment,
    ].join('\n\n');
  }

  /// Kicks the present_activity loop. Sends ONLY the kickoff text + letterId.
  /// Errors degrade visibly (onDrop) rather than throwing out of start().
  Future<void> start() async {
    try {
      await _conversation.sendRequest(genui.ChatMessage.user(kKickoffPrompt));
    } catch (error, stack) {
      debugPrint('[spike] present_activity loop failed to start: $error\n$stack');
      onDrop?.call(error);
    }
  }

  /// The transport onSend: collect text/interaction from the GenUI message, send it
  /// to Gemini, and stream the response back into the A2UI parser via addChunk.
  ///
  /// SECURITY (T-11-03): only text/interaction parts cross the wire — there is no
  /// path here for stroke Offsets or PII to be serialized.
  Future<void> _sendAndReceive(genui.ChatMessage message) async {
    final StringBuffer buffer = StringBuffer();
    for (final genui.StandardPart part in message.parts) {
      if (part.isUiInteractionPart) {
        buffer.write(part.asUiInteractionPart!.interaction);
      } else if (part is genui.TextPart) {
        buffer.write(part.text);
      }
    }
    if (buffer.isEmpty) return;

    try {
      final Stream<GenerateContentResponse> responses =
          _model.generateContentStream(<Content>[Content.text(buffer.toString())]);
      await for (final GenerateContentResponse response in responses) {
        final String? chunk = response.text;
        if (chunk != null && chunk.isNotEmpty) {
          _transport.addChunk(chunk);
        }
      }
    } catch (error, stack) {
      // App Check rejections and other backend errors surface here (D-13/A3).
      debugPrint('[spike] model stream failed: $error\n$stack');
      onDrop?.call(error);
    }
  }

  void _onEvent(ConversationEvent event) {
    switch (event) {
      case ConversationSurfaceAdded(:final String surfaceId):
        onSurfaceAdded?.call(surfaceId);
      case ConversationError(:final Object error):
        debugPrint('[spike] conversation error: $error');
        onDrop?.call(error);
      default:
        break;
    }
  }

  /// Releases GenUI controllers (per the integrate-genui-firebase skill cleanup step).
  void dispose() {
    _conversation.dispose();
    _transport.dispose();
    _controller.dispose();
  }
}
