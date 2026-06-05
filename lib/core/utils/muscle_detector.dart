enum MuscleGroup {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  forearms,
  quads,
  hamstrings,
  calves,
  upperAbs,
  lowerAbs,
  obliques,
  unknown,
}

class MuscleDetector {
  static MuscleGroup detectPrimaryMuscle(
      String exerciseName, String variation) {
    final name = exerciseName.toLowerCase();
    final varStr = variation.toLowerCase();
    final fullText = '$name $varStr';

    // 1. HIGH PRIORITY: Exceptions & Specific Modifiers
    if (fullText.contains('calf') || fullText.contains('calves')) {
      return MuscleGroup.calves;
    }

    if (fullText.contains('reverse pec') ||
        fullText.contains('rear delt') ||
        fullText.contains('face pull') ||
        fullText.contains('reverse fly') ||
        fullText.contains('rear fly')) {
      return MuscleGroup.shoulders; // Rear delts
    }

    if (fullText.contains('reverse forearm') ||
        fullText.contains('reverse wrist')) {
      return MuscleGroup.forearms;
    }

    if (fullText.contains('romanian') ||
        fullText.contains('rdl') ||
        fullText.contains('leg curl')) {
      return MuscleGroup.hamstrings;
    }

    if (fullText.contains('close grip bench')) {
      return MuscleGroup.triceps;
    }

    if (fullText.contains('abductor')) {
      return MuscleGroup
          .quads; // Or glutes, grouped to Quads/Legs for simplicity
    }

    if (fullText.contains('adductor')) {
      return MuscleGroup.quads; // Inner thigh
    }

    if (fullText.contains('twist') || fullText.contains('side bend')) {
      return MuscleGroup.obliques;
    }

    if (fullText.contains('leg raise') ||
        fullText.contains('knee raise') ||
        fullText.contains('l-sit')) {
      return MuscleGroup.lowerAbs;
    }

    if (fullText.contains('crunch') ||
        fullText.contains('plank') ||
        fullText.contains('sit up')) {
      return MuscleGroup.upperAbs;
    }

    // 2. MEDIUM PRIORITY: General Keywords
    // Forearms
    if (fullText.contains('wrist') || fullText.contains('forearm')) {
      return MuscleGroup.forearms;
    }

    // Shoulders
    if (fullText.contains('shoulder') ||
        fullText.contains('lateral raise') ||
        fullText.contains('front raise') ||
        fullText.contains('overhead press') ||
        fullText.contains('raise')) {
      if (!fullText.contains('calf') && !fullText.contains('calves')) {
        return MuscleGroup.shoulders;
      }
    }

    // Triceps
    if (fullText.contains('tricep') ||
        fullText.contains('skull crusher') ||
        fullText.contains('pushdown') ||
        fullText.contains('extension') ||
        fullText.contains('dips')) {
      if (!fullText.contains('leg') && !fullText.contains('lat')) {
        // ignore leg extension, lat pushdown
        return MuscleGroup.triceps;
      }
    }

    // Biceps
    if (fullText.contains('bicep') ||
        fullText.contains('curl') ||
        fullText.contains('preacher')) {
      if (!fullText.contains('leg')) {
        // ignore leg curl
        return MuscleGroup.biceps;
      }
    }

    // Chest
    if (fullText.contains('bench press') ||
        fullText.contains('chest') ||
        fullText.contains('pec') ||
        fullText.contains('fly') ||
        fullText.contains('incline press') ||
        fullText.contains('decline press') ||
        fullText.contains('incline dumbbell press')) {
      if (!fullText.contains('rear')) {
        // avoid rear fly mapping to chest
        return MuscleGroup.chest;
      }
    }

    // Back
    if (fullText.contains('row') ||
        fullText.contains('lat') ||
        fullText.contains('pulldown') ||
        fullText.contains('shrug') ||
        fullText.contains('pull up') ||
        fullText.contains('pull-up')) {
      return MuscleGroup.back;
    }

    // Quads
    if (fullText.contains('squat') ||
        fullText.contains('leg press') ||
        fullText.contains('leg extension') ||
        fullText.contains('lunge')) {
      return MuscleGroup.quads;
    }

    // Hamstrings
    if (fullText.contains('deadlift')) {
      return MuscleGroup.hamstrings;
    }



    return MuscleGroup.unknown;
  }

  static String getMuscleName(MuscleGroup group) {
    switch (group) {
      case MuscleGroup.chest:
        return 'Chest';
      case MuscleGroup.back:
        return 'Back';
      case MuscleGroup.shoulders:
        return 'Shoulders';
      case MuscleGroup.biceps:
        return 'Biceps';
      case MuscleGroup.triceps:
        return 'Triceps';
      case MuscleGroup.forearms:
        return 'Forearms';
      case MuscleGroup.quads:
        return 'Quads';
      case MuscleGroup.hamstrings:
        return 'Hamstrings & Glutes';
      case MuscleGroup.calves:
        return 'Calves';
      case MuscleGroup.upperAbs:
        return 'Upper Abs';
      case MuscleGroup.lowerAbs:
        return 'Lower Abs';
      case MuscleGroup.obliques:
        return 'Obliques';
      case MuscleGroup.unknown:
        return 'Other';
    }
  }
}
