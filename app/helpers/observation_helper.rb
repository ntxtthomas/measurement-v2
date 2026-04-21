# =============================================================================
# ObservationHelper
#
# DELIBERATE SMELL: Score classification logic exists here AND in:
#   - ObservationSession#classify_score (private)
#   - GenerateReportJob#classify_score  (private)
#
# Three places. Subtle differences:
#   - This helper uses a 4-level system (Low/Mid-Low/Mid-High/High)
#   - The model uses 3 levels (Concern/Mixed/Strong)
#   - The job uses 3 levels (Concern/Mixed/Strong) but different cutoffs
#
# This is a realistic example of DRY drift. Refactor task: extract to
# a shared ScoreClassifier value object or module.
#
# Also note: display_average_score duplicates logic from average_score on the model.
# =============================================================================
module ObservationHelper
  # SMELL: 4-level classification differs from 3-level used in model and job
  # Magic numbers 2, 4, 6 baked in — no named constant or configuration
  def display_score_level(score)
    case score
    when 1..2 then "Concern"
    when 3..5 then "Mixed"
    when 6..7 then "Strong"
    else "Unknown"
    end
  end

  def score_level_class(score)
    case score
    when 1..2 then "concern"
    when 3..5 then "mixed"
    when 6..7 then "strong"
    else "unknown"
    end
  end

  # SMELL: Duplicates ObservationSession#average_score but formats the output.
  # The formatting could have been added to the model or a decorator.
  # Instead we have two average-calculation implementations.
  def display_average_score(session)
    scores = session.observation_scores
    return "—" if scores.empty?

    # SMELL: loads scores into Ruby instead of using SQL AVG
    avg = scores.map(&:score).sum.to_f / scores.count
    number_with_precision(avg, precision: 2)
  end

  # SMELL: Used in multiple views but slightly different from the model method.
  # Candidate for a shared presenter or decorator.
  def completion_badge_class(rate)
    if rate == 100
      "strong"
    elsif rate > 50
      "mixed"
    else
      "concern"
    end
  end
end
