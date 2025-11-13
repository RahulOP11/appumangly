import '../models/meditation_models.dart';

class MeditationDataService {
  
  // Free Guided Meditation Sessions
  static List<MeditationSession> getFreeMeditationSessions() {
    return [
      MeditationSession(
        id: '1',
        title: 'Stress Relief Meditation',
        duration: '10 min',
        description: 'Release tension and find inner calm with this gentle guided meditation',
        difficulty: 'Beginner',
        category: 'Stress Relief',
        audioUrl: 'tts_stress_relief', // Will use TTS
        imageUrl: 'assets/meditation/stress.png',
        instructor: 'AI Guide',
        tags: ['stress', 'relaxation', 'calm'],
      ),
      MeditationSession(
        id: '2',
        title: 'Anxiety Relief',
        duration: '15 min',
        description: 'Gentle guidance to ease anxiety and restore peace of mind',
        difficulty: 'Beginner',
        category: 'Anxiety',
        audioUrl: 'tts_anxiety_relief',
        imageUrl: 'assets/meditation/anxiety.png',
        instructor: 'AI Guide',
        tags: ['anxiety', 'peace', 'comfort'],
      ),
      MeditationSession(
        id: '3',
        title: 'Focus & Concentration',
        duration: '20 min',
        description: 'Enhance mental clarity and improve concentration power',
        difficulty: 'Intermediate',
        category: 'Focus',
        audioUrl: 'tts_focus_meditation',
        imageUrl: 'assets/meditation/focus.png',
        instructor: 'AI Guide',
        tags: ['focus', 'concentration', 'clarity'],
      ),
      MeditationSession(
        id: '4',
        title: 'Sleep Preparation',
        duration: '25 min',
        description: 'Prepare your mind and body for restful, deep sleep',
        difficulty: 'Beginner',
        category: 'Sleep',
        audioUrl: 'tts_sleep_meditation',
        imageUrl: 'assets/meditation/sleep.png',
        instructor: 'AI Guide',
        tags: ['sleep', 'rest', 'bedtime'],
      ),
      MeditationSession(
        id: '5',
        title: 'Body Scan Relaxation',
        duration: '30 min',
        description: 'Progressive muscle relaxation for complete physical tension release',
        difficulty: 'Intermediate',
        category: 'Relaxation',
        audioUrl: 'tts_body_scan',
        imageUrl: 'assets/meditation/body_scan.png',
        instructor: 'AI Guide',
        tags: ['body scan', 'relaxation', 'tension'],
      ),
      MeditationSession(
        id: '6',
        title: 'Self-Compassion',
        duration: '18 min',
        description: 'Cultivate kindness and compassion towards yourself',
        difficulty: 'Intermediate',
        category: 'Emotional',
        audioUrl: 'tts_self_compassion',
        imageUrl: 'assets/meditation/compassion.png',
        instructor: 'AI Guide',
        tags: ['self-love', 'compassion', 'emotional'],
      ),
      MeditationSession(
        id: '7',
        title: 'Morning Mindfulness',
        duration: '12 min',
        description: 'Start your day with intention and peaceful awareness',
        difficulty: 'Beginner',
        category: 'Mindfulness',
        audioUrl: 'tts_morning_mindfulness',
        imageUrl: 'assets/meditation/morning.png',
        instructor: 'AI Guide',
        tags: ['morning', 'mindfulness', 'awareness'],
      ),
      MeditationSession(
        id: '8',
        title: 'Gratitude Practice',
        duration: '15 min',
        description: 'Cultivate appreciation and positive emotions through gratitude',
        difficulty: 'Beginner',
        category: 'Emotional',
        audioUrl: 'tts_gratitude',
        imageUrl: 'assets/meditation/gratitude.png',
        instructor: 'AI Guide',
        tags: ['gratitude', 'appreciation', 'positive'],
      ),
    ];
  }

  // Breathing Patterns
  static List<BreathingPattern> getBreathingPatterns() {
    return [
      BreathingPattern(
        name: '4-7-8 Relaxation',
        description: 'Dr. Andrew Weil\'s famous relaxation technique',
        inhale: 4,
        hold: 7,
        exhale: 8,
        difficulty: 'Beginner',
      ),
      BreathingPattern(
        name: 'Box Breathing',
        description: 'Navy SEAL technique for stress and focus',
        inhale: 4,
        hold: 4,
        exhale: 4,
        difficulty: 'Beginner',
      ),
      BreathingPattern(
        name: 'Simple 4-4',
        description: 'Easy breathing for beginners',
        inhale: 4,
        hold: 0,
        exhale: 4,
        difficulty: 'Beginner',
      ),
      BreathingPattern(
        name: 'Coherent Breathing',
        description: 'Heart-brain coherence technique',
        inhale: 5,
        hold: 0,
        exhale: 5,
        difficulty: 'Intermediate',
      ),
      BreathingPattern(
        name: 'Energizing Breath',
        description: 'Quick energizing technique',
        inhale: 2,
        hold: 2,
        exhale: 2,
        difficulty: 'Advanced',
      ),
    ];
  }

  // Nature Sounds and Ambient Audio
  static List<SoundCategory> getSoundCategories() {
    return [
      SoundCategory(
        name: 'Nature Sounds',
        description: 'Calming sounds from nature',
        icon: '🌿',
        tracks: [
          SoundTrack(
            id: 'rain',
            name: 'Gentle Rain',
            url: 'rain_sound', // Placeholder - would use real audio
            duration: 'Continuous',
          ),
          SoundTrack(
            id: 'ocean',
            name: 'Ocean Waves',
            url: 'ocean_sound',
            duration: 'Continuous',
          ),
          SoundTrack(
            id: 'forest',
            name: 'Forest Birds',
            url: 'forest_sound',
            duration: 'Continuous',
          ),
          SoundTrack(
            id: 'thunder',
            name: 'Distant Thunder',
            url: 'thunder_sound',
            duration: 'Continuous',
          ),
        ],
      ),
      SoundCategory(
        name: 'White Noise',
        description: 'Consistent background sounds',
        icon: '🔊',
        tracks: [
          SoundTrack(
            id: 'white_noise',
            name: 'Pure White Noise',
            url: 'white_noise_sound',
            duration: 'Continuous',
          ),
          SoundTrack(
            id: 'pink_noise',
            name: 'Pink Noise',
            url: 'pink_noise_sound',
            duration: 'Continuous',
          ),
          SoundTrack(
            id: 'brown_noise',
            name: 'Brown Noise',
            url: 'brown_noise_sound',
            duration: 'Continuous',
          ),
        ],
      ),
      SoundCategory(
        name: 'Instrumental',
        description: 'Peaceful instrumental music',
        icon: '🎵',
        tracks: [
          SoundTrack(
            id: 'piano',
            name: 'Soft Piano',
            url: 'piano_sound',
            duration: 'Continuous',
          ),
          SoundTrack(
            id: 'flute',
            name: 'Bamboo Flute',
            url: 'flute_sound',
            duration: 'Continuous',
          ),
          SoundTrack(
            id: 'bells',
            name: 'Tibetan Bells',
            url: 'bells_sound',
            duration: 'Continuous',
          ),
        ],
      ),
    ];
  }

  // Meditation Scripts for TTS
  static Map<String, String> getMeditationScripts() {
    return {
      'tts_stress_relief': '''
        Welcome to this 10-minute stress relief meditation. Find a comfortable seated position with your back straight but not rigid. Close your eyes softly or maintain a gentle gaze downward.
        
        Begin by taking three deep, cleansing breaths. Inhale through your nose for four counts... hold for two... and exhale slowly through your mouth for six counts. Let go of any tension with each exhale.
        
        Now allow your breathing to return to its natural rhythm. Simply observe each breath without trying to control it.
        
        Starting from the top of your head, scan your body for areas of tension. Notice your forehead... are there any wrinkles of worry? Let them smooth away.
        
        Check your jaw... many people hold stress here. Let your jaw drop slightly open, releasing any tightness.
        
        Move your attention to your shoulders. Are they raised toward your ears? Let them drop down and back, creating space around your neck.
        
        Continue this body scan, releasing tension from your arms... your chest... your back... your stomach... your hips... your legs... and finally your feet.
        
        Now imagine a warm, golden light entering through the crown of your head with each inhale. This healing light flows through your entire body, dissolving any remaining stress or tension.
        
        With each exhale, imagine breathing out dark smoke - this represents all your worries, fears, and stress leaving your body.
        
        Continue this visualization for several more breaths. Golden healing light in... dark stress and tension out.
        
        Now bring to mind this affirmation: "I release what I cannot control. I am calm, centered, and at peace." Repeat this silently to yourself three times.
        
        Take a moment to appreciate this feeling of calm that you've created. Know that you can return to this peaceful state anytime you need it.
        
        Begin to deepen your breath again. Wiggle your fingers and toes. When you're ready, slowly open your eyes and carry this sense of peace with you into your day.
      ''',
      
      'tts_anxiety_relief': '''
        Welcome to this anxiety relief meditation. You are in a safe space. Begin by finding a comfortable position where you feel supported.
        
        Place one hand on your chest and one on your belly. This will help you focus on breathing with your diaphragm, which activates your body's relaxation response.
        
        Close your eyes and take a moment to acknowledge that anxiety is a natural human emotion. It's your body trying to protect you, but right now, you are safe.
        
        Begin the 4-7-8 breathing technique. Inhale through your nose for 4 counts... hold your breath for 7 counts... now exhale through your mouth for 8 counts, making a soft "whoosh" sound.
        
        Repeat this cycle three more times. This technique helps activate your parasympathetic nervous system, naturally reducing anxiety.
        
        Now return to normal breathing and imagine you're sitting by a calm lake. The water is perfectly still, reflecting the peaceful sky above.
        
        As anxious thoughts arise, imagine them as leaves floating on the surface of this lake. You can observe them, but they don't disturb the deep calm beneath the water.
        
        Let each worry-thought drift away like a leaf carried gently by the current. You don't need to fight them or judge them - simply let them pass.
        
        Focus on the sensation of your breath. Each inhale brings fresh calm and clarity. Each exhale releases tension and worry.
        
        Bring to mind this truth: "This feeling will pass. I have weathered storms before, and I am stronger than I know."
        
        Visualize a protective bubble of white light surrounding you. Nothing harmful can penetrate this bubble. You are completely safe and protected.
        
        Notice how your body feels now - perhaps lighter, more relaxed. Your breathing has naturally slowed and deepened.
        
        As we conclude, place both hands on your heart and offer yourself some compassion: "May I be kind to myself. May I find peace. May I remember that I am enough."
        
        Take three deep breaths, gently move your body, and when you're ready, open your eyes with a sense of calm confidence.
      ''',
      
      'tts_focus_meditation': '''
        Welcome to this 20-minute focus and concentration meditation. This practice will strengthen your ability to maintain attention and mental clarity.
        
        Sit with your spine erect, shoulders relaxed, and hands resting comfortably. Close your eyes and establish your intention to cultivate focused awareness.
        
        Begin with mindful breathing. Breathe naturally and count each exhale: one... two... three... up to ten, then start again at one.
        
        When your mind wanders - and it will - simply notice where it went without judgment, and gently return to counting your breaths.
        
        This is not about perfect concentration, but about noticing when attention drifts and kindly bringing it back. Each return strengthens your focus muscle.
        
        Now shift to single-pointed concentration. Focus your attention on the sensation of breath at the tip of your nostrils.
        
        Notice the subtle differences between the in-breath and out-breath. The in-breath might feel cooler, the out-breath warmer.
        
        When thoughts arise - plans, memories, judgments - acknowledge them briefly and return to the breath sensation at your nostrils.
        
        Imagine your mind as a clear mountain lake. Thoughts are like ripples on the surface, but the deep water beneath remains calm and undisturbed.
        
        If your mind becomes very busy, try the noting technique. When a thought arises, gently note "thinking" and return to your breath anchor.
        
        For the next few minutes, practice unwavering attention to your chosen focus point. Each moment of sustained attention builds your concentration power.
        
        Now expand your awareness to include sounds around you, but maintain the breath as your primary focus. This trains flexible attention.
        
        As we prepare to conclude, set an intention to carry this focused awareness into your daily activities.
        
        Remember: every moment of mindful attention is valuable practice. Your mind is becoming sharper and more focused.
        
        Take three conscious breaths, wiggle your fingers and toes, and slowly open your eyes with enhanced mental clarity.
      ''',
      
      'tts_sleep_meditation': '''
        Welcome to this sleep preparation meditation. You've completed your day, and now it's time to prepare your body and mind for restorative sleep.
        
        Lie down comfortably in your bed. Adjust your pillow and blankets so you feel completely supported. Close your eyes and let your body settle.
        
        Begin by releasing the day. With each exhale, let go of any conversations, tasks, or concerns from today. They can wait until tomorrow.
        
        Start a progressive muscle relaxation, beginning with your feet. Tense the muscles in your feet for 5 seconds... now release and feel the relaxation spread through your feet.
        
        Move to your calves... tense... hold... and release. Feel the muscles becoming heavy and relaxed.
        
        Continue with your thighs... tense... hold... and let go. Your legs are now completely relaxed and heavy.
        
        Clench your fists and tense your arms... hold... and release. Let your arms sink into the bed.
        
        Scrunch your shoulders up to your ears... hold... and drop them down. Feel the tension melting away.
        
        Tense your entire face - forehead, eyes, jaw... hold... and completely relax. Your face is now soft and peaceful.
        
        Now your entire body is deeply relaxed and heavy. Imagine sinking gently into your bed like you're floating on a calm, warm sea.
        
        Begin counting backwards from 100, but count very slowly: 100... 99... 98... If you lose count, simply start again from where you remember.
        
        With each number, you become twice as relaxed and drowsy. Your mind is becoming quiet and peaceful.
        
        Imagine you're in a beautiful, safe place - perhaps a cozy cabin, a peaceful beach, or a serene garden. You are completely safe and protected here.
        
        Allow any remaining thoughts to drift away like clouds across a night sky. Your mind is becoming as still as a calm lake.
        
        Your breath is slow and natural now. Your body is heavy and relaxed. Your mind is quiet and peaceful.
        
        Let yourself drift naturally toward sleep. You are safe to rest deeply and wake refreshed in the morning.
        
        Sleep peacefully...
      ''',

      'tts_body_scan': '''
        Welcome to this 30-minute body scan meditation for complete relaxation. This practice will help you release physical tension and develop body awareness.
        
        Lie down comfortably with your arms at your sides, palms facing up. Close your eyes and take three deep breaths to settle in.
        
        Begin by noticing your body as a whole, lying here in this moment. Feel the weight of your body against the surface beneath you.
        
        Now bring your attention to the top of your head. Notice any sensations here - warmth, tingling, pressure, or perhaps nothing at all. Simply observe without judgment.
        
        Move your attention to your forehead. Often we hold tension here from concentration or worry. Consciously soften and smooth your forehead.
        
        Notice your eyes, even though they're closed. Let them rest deeply in their sockets. Soften the muscles around your eyes.
        
        Bring awareness to your cheeks, your nose, your mouth. Let your jaw drop slightly open and your tongue rest gently in your mouth.
        
        Move to your neck and throat area. This is where many people hold stress. Breathe into this area and let it soften completely.
        
        Notice your shoulders. Are they raised or tight? Let them melt away from your ears and sink into the surface beneath you.
        
        Scan your right arm, starting from the shoulder... down through your upper arm... your elbow... your forearm... your wrist... each finger of your right hand. Let this entire arm become heavy and relaxed.
        
        Now your left arm in the same way. Shoulder... upper arm... elbow... forearm... wrist... each finger. Both arms are now completely relaxed.
        
        Bring attention to your chest. Notice it rising and falling with each natural breath. Let your ribcage expand and soften.
        
        Move to your upper back, the area between your shoulder blades. Breathe into any tension here and let it dissolve.
        
        Notice your heart region. Send appreciation to your heart for beating faithfully all day, every day of your life.
        
        Scan your abdomen. This area often holds emotional tension. Breathe deeply into your belly and let it soften completely.
        
        Notice your lower back. If there's any discomfort here, simply acknowledge it with kindness and breathe into the area.
        
        Bring awareness to your hips and pelvis. These large joints often store tension from sitting or standing. Let them relax completely.
        
        Scan your right leg now: your thigh... your knee... your calf... your ankle... each toe of your right foot. Let this leg become heavy and still.
        
        Now your left leg: thigh... knee... calf... ankle... each toe. Both legs are now completely relaxed and heavy.
        
        Take a moment to scan your entire body one more time. Notice how different it feels now compared to when you began.
        
        Rest in this state of complete physical relaxation. Your body knows how to heal and restore itself when you give it permission to relax.
        
        If you notice your mind becoming active, simply return attention to the sensations in your body.
        
        As we conclude, send gratitude to your body for carrying you through life. It deserves this care and attention.
        
        Begin to deepen your breath. Gently wiggle your fingers and toes. When you're ready, slowly open your eyes, carrying this relaxation with you.
      ''',

      'tts_self_compassion': '''
        Welcome to this self-compassion meditation. Today you will practice offering yourself the same kindness you would give to a dear friend.
        
        Sit comfortably and close your eyes. Place your hands on your heart and feel its steady rhythm. This simple gesture activates your body's care-giving system.
        
        Begin by acknowledging that being human means experiencing pain, making mistakes, and facing challenges. You are not alone in this.
        
        Bring to mind a situation where you've been self-critical or harsh with yourself. Perhaps a mistake you made, a goal you didn't reach, or a way you feel you've fallen short.
        
        Notice any emotions that arise - shame, disappointment, anger. Simply acknowledge these feelings without trying to change them.
        
        Now imagine a dear friend was going through the exact same situation. What would you say to them? How would you comfort them?
        
        You would likely offer understanding, remind them of their good qualities, and help them see the bigger picture. You deserve this same kindness.
        
        Place your hands on your heart again and offer yourself these words: "May I be kind to myself in this moment. May I give myself the compassion I need."
        
        Recognize that your pain and struggles are part of the shared human experience. Millions of people have faced similar challenges.
        
        Say to yourself: "May I remember that I am not alone. May I find connection in our shared humanity."
        
        Now focus on your own precious humanity. You are a being worthy of love and kindness, simply because you exist.
        
        Offer yourself this loving-kindness: "May I be happy. May I be peaceful. May I be free from unnecessary suffering. May I live with ease."
        
        If you notice your inner critic trying to argue against these kind wishes, simply acknowledge it and return to self-compassion.
        
        Think of your future self facing challenges. How can you be a loving, supportive inner friend to yourself?
        
        Commit to speaking to yourself with the same kindness you would offer a beloved friend. You deserve your own compassion.
        
        As we conclude, keep your hands on your heart and take in this feeling of self-acceptance and love.
        
        Remember: self-compassion is not self-indulgence, but the foundation of genuine healing and growth.
        
        Take three deep breaths, and when you're ready, open your eyes with a commitment to treat yourself with kindness today.
      ''',

      'tts_morning_mindfulness': '''
        Good morning, and welcome to this mindful start to your day. This practice will help you begin with intention and presence.
        
        Sit comfortably with your spine naturally erect. Close your eyes and take a moment to arrive fully in this new day.
        
        Begin with gratitude. Take a deep breath and appreciate that you have awakened to another day of possibilities.
        
        Notice how your body feels this morning. Are you energized, tired, stiff, comfortable? Simply observe without judgment.
        
        Set an intention to be present for whatever this day brings. You don't need to control every moment, but you can choose how you meet each experience.
        
        Bring attention to your breath. Each inhale brings fresh energy and potential. Each exhale releases any residue from sleep or dreams.
        
        Now practice mindful listening. Without opening your eyes, notice all the sounds around you - birds, traffic, household sounds, or silence.
        
        These sounds are part of the symphony of life happening right now. You are an aware participant in this moment.
        
        Bring to mind your plans for today. Rather than rushing into mental planning, simply acknowledge what lies ahead with calm awareness.
        
        Ask yourself: "How do I want to show up today? What qualities do I want to embody?"
        
        Perhaps you want to be patient, kind, focused, creative, or courageous. Set this intention in your heart.
        
        Imagine moving through your day with mindful awareness - being fully present for conversations, meals, work, and even routine tasks.
        
        See yourself responding rather than reacting to challenges. Feel yourself appreciating small moments of beauty and connection.
        
        Now scan your body once more. Send appreciation to your legs that will carry you, your hands that will work, your mind that will think.
        
        Take three conscious breaths, feeling grateful for this opportunity to live another day.
        
        As you prepare to open your eyes, carry this intention with you: "I will remember to pause, breathe, and be present throughout this day."
        
        Slowly open your eyes and step into your day with mindful awareness and heartfelt intention.
      ''',

      'tts_gratitude': '''
        Welcome to this gratitude meditation. Today you will cultivate appreciation and open your heart to the goodness in your life.
        
        Sit comfortably with your hands resting on your heart. Close your eyes and feel the warmth beneath your palms.
        
        Begin with appreciating the simple fact that you are alive in this moment. Your heart is beating, your lungs are breathing, your mind is aware.
        
        Think of three things you often take for granted: perhaps your ability to see, hear, walk, or think. Take a moment to truly appreciate each one.
        
        Now bring to mind someone you love deeply - a family member, friend, partner, or even a beloved pet. Feel the warmth that arises when you think of them.
        
        Appreciate this person's presence in your life. How have they enriched your experience? What qualities do you cherish about them?
        
        Expand your gratitude to include challenges you've overcome. Even difficult experiences have taught you resilience and given you wisdom.
        
        Think of a specific challenge from your past that ultimately made you stronger or wiser. Can you find appreciation for the growth it brought?
        
        Now appreciate the small comforts in your life: a roof over your head, clean water, food, comfortable clothes, or a warm bed.
        
        Millions of people lack these basic necessities. Feel grateful for these simple yet profound gifts.
        
        Bring to mind a moment of natural beauty you've witnessed: a sunset, flowers blooming, snow falling, or waves on a shore.
        
        Feel appreciation for the magnificent planet that supports all life. You are part of this incredible web of existence.
        
        Think of your own unique qualities and abilities. What talents, skills, or positive traits do you possess? Appreciate your own goodness.
        
        Now expand your gratitude to include strangers who make your life possible: farmers who grow food, workers who maintain infrastructure, doctors, teachers.
        
        Feel connected to this vast network of human cooperation and care.
        
        As we conclude, place both hands on your heart and repeat silently: "Thank you for this life. Thank you for this moment. Thank you for the gift of awareness itself."
        
        Let this feeling of gratitude fill your entire being. Notice how appreciation naturally opens your heart and creates a sense of abundance.
        
        Commit to carrying this grateful heart with you throughout your day. Look for moments to appreciate, however small.
        
        Take three deep breaths, and open your eyes with a heart full of gratitude and wonder.
      '''
    };
  }
}