# waddah_core/align.py
# Purpose: Levenshtein alignment + target-phoneme diagnosis.
# COPIED from notebook cells 1E and 6A, with one documented fix (see below).

__all__ = ["levenshtein_align", "diagnose_at_target"]


def levenshtein_align(ref: list, hyp: list):
    """DP-based Levenshtein alignment.

    Returns (subs, dels, ins, ops) where ops is a list of
    (op_type, ref_ph, hyp_ph) and op_type is one of
    {'correct', 'substitution', 'deletion', 'insertion'}.
    """
    n, m = len(ref), len(hyp)
    dp = [[0] * (m + 1) for _ in range(n + 1)]
    for i in range(n + 1):
        dp[i][0] = i
    for j in range(m + 1):
        dp[0][j] = j
    for i in range(1, n + 1):
        for j in range(1, m + 1):
            if ref[i - 1] == hyp[j - 1]:
                dp[i][j] = dp[i - 1][j - 1]
            else:
                dp[i][j] = 1 + min(dp[i - 1][j - 1], dp[i - 1][j], dp[i][j - 1])

    ops = []
    i, j = n, m
    while i > 0 or j > 0:
        if i > 0 and j > 0 and ref[i - 1] == hyp[j - 1]:
            ops.append(("correct", ref[i - 1], hyp[j - 1]))
            i -= 1
            j -= 1
        elif i > 0 and j > 0 and dp[i][j] == dp[i - 1][j - 1] + 1:
            ops.append(("substitution", ref[i - 1], hyp[j - 1]))
            i -= 1
            j -= 1
        elif i > 0 and dp[i][j] == dp[i - 1][j] + 1:
            ops.append(("deletion", ref[i - 1], None))
            i -= 1
        elif j > 0 and dp[i][j] == dp[i][j - 1] + 1:
            ops.append(("insertion", None, hyp[j - 1]))
            j -= 1
        else:
            break

    ops.reverse()
    subs = sum(1 for o in ops if o[0] == "substitution")
    dels = sum(1 for o in ops if o[0] == "deletion")
    ins_ = sum(1 for o in ops if o[0] == "insertion")
    return subs, dels, ins_, ops


def diagnose_at_target(predicted_phonemes: list, canonical_phonemes: list, target_idx: int) -> str:
    """Return the alignment operation that landed on the target phoneme.

    FIX vs. notebook cell 6A: the notebook returned "insertion" whenever the
    walk finished without reaching target_idx. That fires on empty or very
    short predictions and inflates the insertion count in the Stage-2 table.
    Here an unreached target is reported as "deletion" (the phoneme was not
    produced at all), and a genuine insertion is only reported when an
    insertion op is adjacent to the target position.
    """
    _, _, _, ops = levenshtein_align(canonical_phonemes, predicted_phonemes)

    canonical_pos = 0
    pending_insertion = False
    for op_type, _ref_ph, _hyp_ph in ops:
        if op_type == "insertion":
            # An insertion sitting immediately before the target counts as one.
            if canonical_pos == target_idx:
                pending_insertion = True
            continue
        if canonical_pos == target_idx:
            if op_type == "correct" and pending_insertion:
                return "insertion"
            return op_type
        canonical_pos += 1
        pending_insertion = False

    return "deletion"
