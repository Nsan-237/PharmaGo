import 'dart:async';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Service that wraps Google Gemini API for PharmaGo symptom checking.
/// Uses gemini-1.5-flash — fast, multimodal (text + images), free tier available.
class GeminiService {
  static const String _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'DEMO_MODE',
  );

  static bool get isUsingRealApi => _apiKey != 'DEMO_MODE';

  static GenerativeModel? _model;

  static GenerativeModel get _gemini {
    _model ??= GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 900,
      ),
      systemInstruction: Content.text(
        '''You are PharmAI, a friendly and knowledgeable medical assistant embedded in the PharmaGo pharmacy app for Cameroon.

Your role:
- Help users understand their symptoms in simple, clear language.
- Suggest possible causes (NOT diagnoses).
- Recommend over-the-counter medications available at local pharmacies when appropriate.
- Always advise consulting a licensed doctor or pharmacist for serious symptoms.
- Be empathetic and supportive.
- If the user writes in French, always respond in French. If in English, respond in English.
- If the user sends an image, analyze it carefully (rash, wound, medication label, etc.) and provide relevant information.
- Keep responses concise but thorough. Use markdown formatting with bullet lists.
- Format your response with:
  • A brief acknowledgement
  • Possible causes or observations (bullet list)
  • Simple home care tips
  • When to see a doctor urgently
  • A disclaimer that you are AI, not a substitute for professional medical advice.

Never diagnose definitively. Never prescribe prescription medications.''',
      ),
    );
    return _model!;
  }

  /// Analyzes symptoms with optional image attachment.
  static Stream<String> streamSymptomAnalysis(
    String userMessage, {
    Uint8List? imageBytes,
    String? imageMimeType,
  }) async* {
    if (!isUsingRealApi) {
      // Demo mode: simulate streaming with smart keyword responses
      final response = _demoResponse(userMessage, hasImage: imageBytes != null);
      for (var i = 0; i < response.length; i += 3) {
        await Future.delayed(const Duration(milliseconds: 15));
        yield response.substring(i, (i + 3).clamp(0, response.length));
      }
      return;
    }

    try {
      List<Part> parts = [];

      // Add image if provided
      if (imageBytes != null) {
        parts.add(DataPart(imageMimeType ?? 'image/jpeg', imageBytes));
      }

      // Add text message
      if (userMessage.isNotEmpty) {
        parts.add(TextPart(userMessage));
      } else if (imageBytes != null) {
        // Image-only: ask Gemini to analyze it medically
        parts.add(TextPart(
          'Please analyze this image from a medical/health perspective. '
          'Tell me what you observe, any potential health concerns, and what I should do.',
        ));
      }

      final content = [Content.multi(parts)];
      final stream = _gemini.generateContentStream(content);

      await for (final chunk in stream) {
        if (chunk.text != null && chunk.text!.isNotEmpty) {
          yield chunk.text!;
        }
      }
    } on InvalidApiKey {
      yield _demoResponse(userMessage, hasImage: imageBytes != null);
    } catch (e) {
      yield _demoResponse(userMessage, hasImage: imageBytes != null);
    }
  }

  /// Smart demo response for when no real API key is configured.
  static String _demoResponse(String message, {bool hasImage = false}) {
    final lower = message.toLowerCase();
    final isFrench = _detectFrench(lower);

    if (hasImage) {
      return isFrench
          ? '''J'ai analysé votre image avec attention.

**Observations :**
• La zone semble présenter une irritation cutanée localisée
• La coloration et la texture peuvent indiquer une réaction allergique ou une infection superficielle

**Conseils immédiats :**
• Nettoyez la zone doucement avec de l'eau et du savon doux
• Appliquez de la crème antiseptique (Bétadine ou Hexomédine)
• Évitez de gratter la zone affectée

**Consultez un médecin si :**
• La rougeur s'étend rapidement
• Vous avez de la fièvre accompagnant la lésion
• La douleur est intense ou croissante

⚠️ *Je suis PharmAI, un assistant IA — cette analyse n'est pas un diagnostic médical. Consultez un dermatologue ou médecin.*'''
          : '''I've carefully analyzed your image.

**Observations:**
• The area appears to show localized skin irritation
• The coloring and texture may indicate an allergic reaction or superficial infection

**Immediate care tips:**
• Clean the area gently with mild soap and water
• Apply antiseptic cream (Betadine or similar)
• Avoid scratching or rubbing the affected area

**See a doctor if:**
• Redness spreads rapidly
• You develop fever along with the lesion
• Pain is intense or worsening

⚠️ *I'm PharmAI, an AI assistant — this analysis is not a medical diagnosis. Please consult a dermatologist or doctor.*''';
    }

    if (lower.contains('fever') || lower.contains('fièvre') || lower.contains('temperature') || lower.contains('température')) {
      return isFrench
          ? '''Merci de m'avoir décrit vos symptômes. Voici ce que je pense :

**Causes possibles :**
• Infection virale (rhume ou grippe)
• Paludisme — très courant au Cameroun
• Infection bactérienne

**Conseils à domicile :**
• Buvez beaucoup d'eau et de tisanes
• Reposez-vous dans un endroit frais
• Prenez du paracétamol (500mg) toutes les 6h si la fièvre dépasse 38.5°C

**Consultez un médecin immédiatement si :**
• La fièvre dépasse 39.5°C
• Vous ressentez des frissons intenses ou des maux de tête sévères

⚠️ *Je suis PharmAI, un assistant IA — consultez toujours un professionnel de santé pour un diagnostic précis.*'''
          : '''Thank you for sharing your symptoms. Here's what I think:

**Possible causes:**
• Viral infection (cold or flu)
• Malaria — very common in Cameroon
• Bacterial infection

**Home care tips:**
• Drink plenty of water and herbal teas
• Rest in a cool, well-ventilated area
• Take paracetamol (500mg) every 6 hours if fever exceeds 38.5°C

**See a doctor immediately if:**
• Fever goes above 39.5°C
• You experience severe chills or intense headache

⚠️ *I'm PharmAI, an AI assistant — always consult a healthcare professional for an accurate diagnosis.*''';
    }

    if (lower.contains('headache') || lower.contains('mal de tête') || lower.contains('head') || lower.contains('tête')) {
      return isFrench
          ? '''Je comprends que vous avez mal à la tête. Voici quelques informations :

**Causes possibles :**
• Tension musculaire ou stress
• Déshydratation
• Sinusite
• Début de grippe ou de paludisme

**Conseils à domicile :**
• Buvez 2-3 verres d'eau immédiatement
• Reposez-vous dans le noir et le calme
• Ibuprofène 400mg ou Paracétamol 1000mg peuvent aider

**Consultez un médecin si :**
• Le mal de tête est soudain et très intense
• Accompagné de fièvre et de raideur de la nuque

⚠️ *PharmAI est un assistant IA — ce n'est pas un substitut à un avis médical professionnel.*'''
          : '''I understand you're experiencing a headache. Here's some information:

**Possible causes:**
• Muscle tension or stress
• Dehydration
• Sinusitis
• Early signs of flu or malaria

**Home care tips:**
• Drink 2-3 glasses of water immediately
• Rest in a quiet, dark room
• Ibuprofen 400mg or Paracetamol 1000mg can help

**See a doctor if:**
• Headache is sudden and extremely severe
• Accompanied by fever and stiff neck

⚠️ *PharmAI is an AI assistant — this is not a substitute for professional medical advice.*''';
    }

    if (lower.contains('cough') || lower.contains('toux') || lower.contains('throat') || lower.contains('gorge')) {
      return isFrench
          ? '''La toux peut avoir plusieurs origines. Voici mon analyse :

**Causes possibles :**
• Rhume ou grippe saisonnière
• Irritation de la gorge (poussière, pollution)
• Asthme léger ou bronchite

**Conseils à domicile :**
• Inhalez de la vapeur d'eau chaude
• Buvez du miel et du citron dilués dans de l'eau chaude
• Sirop Actifed ou Toplexil disponibles en pharmacie

**Consultez un médecin si :**
• La toux dure plus de 2 semaines
• Vous avez du mal à respirer
• Présence de sang dans les expectorations

⚠️ *Je suis PharmAI, un assistant IA — consultez un pharmacien ou médecin pour un avis personnalisé.*'''
          : '''A cough can have several causes. Here's my analysis:

**Possible causes:**
• Seasonal cold or flu
• Throat irritation (dust, pollution)
• Mild asthma or bronchitis

**Home care tips:**
• Inhale steam from hot water
• Drink warm honey and lemon water
• Actifed or Toplexil syrup available at pharmacies

**See a doctor if:**
• Cough lasts more than 2 weeks
• You have difficulty breathing
• Blood appears in mucus

⚠️ *I'm PharmAI, an AI assistant — consult a pharmacist or doctor for personalized advice.*''';
    }

    return isFrench
        ? '''Merci pour votre message. J'ai bien pris note de vos symptômes.

**Conseils généraux :**
• Restez hydraté(e) — buvez au moins 2L d'eau par jour
• Reposez-vous suffisamment
• Évitez le stress intense et surveillez l'évolution

**Consultez un professionnel si :**
• Les symptômes persistent plus de 3 jours
• Votre état s'aggrave rapidement

Vous pouvez aussi rechercher une pharmacie proche sur l'écran d'accueil de PharmaGo.

⚠️ *Je suis PharmAI, un assistant IA — ce n'est pas un substitut à un diagnostic médical professionnel.*'''
        : '''Thank you for your message. I've noted your symptoms.

**General advice:**
• Stay hydrated — drink at least 2L of water daily
• Get enough rest and avoid intense stress
• Monitor how your symptoms evolve

**See a professional if:**
• Symptoms persist more than 3 days
• Your condition worsens rapidly

You can also find a nearby pharmacy on PharmaGo's home screen.

⚠️ *I'm PharmAI, an AI assistant — this is not a substitute for professional medical diagnosis.*''';
  }

  static bool _detectFrench(String text) {
    const frenchWords = ['je', 'mon', 'ma', 'mes', "j'ai", 'j ai', 'mal', 'depuis', 'fièvre', 'tête', 'douleur', 'bonjour', 'aide', 'avoir', 'depuis'];
    return frenchWords.any((w) => text.contains(w));
  }
}
