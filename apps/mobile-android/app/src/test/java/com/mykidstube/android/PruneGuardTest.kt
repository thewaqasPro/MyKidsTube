package com.mykidstube.android

import org.junit.Assert.*
import org.junit.Test

class PruneGuardTest {

    sealed class PruneDecision {
        data object KeepLocalLibrary : PruneDecision()
        data class PruneImmediately(val videoIds: List<String>) : PruneDecision()
        data class HoldForParentConfirmation(val videoIds: List<String>, val pruneRatio: Double) : PruneDecision()
    }

    private fun evaluatePruneGuard(
        localVideoIds: List<String>,
        incomingVideoIds: List<String>,
        isCatalogClearedExplicitly: Boolean,
        allowMassPrune: Boolean = false
    ): PruneDecision {
        val validIncomingSet = incomingVideoIds.toSet()

        if (incomingVideoIds.isEmpty()) {
            return if (!isCatalogClearedExplicitly) {
                // Rule: Ambiguous empty response -> Never prune or wipe!
                PruneDecision.KeepLocalLibrary
            } else {
                // Explicit server signal that catalog was intentionally cleared
                if (localVideoIds.isNotEmpty() && !allowMassPrune) {
                    PruneDecision.HoldForParentConfirmation(localVideoIds, 1.0)
                } else {
                    PruneDecision.PruneImmediately(localVideoIds)
                }
            }
        }

        val toDelete = localVideoIds.filter { !validIncomingSet.contains(it) }
        if (toDelete.isEmpty()) {
            return PruneDecision.PruneImmediately(emptyList())
        }

        val pruneRatio = toDelete.size.toDouble() / localVideoIds.size.toDouble()
        return if (!allowMassPrune && localVideoIds.size > 2 && pruneRatio > 0.50) {
            // Safety cap: Never delete more than 50% without explicit parent confirmation
            PruneDecision.HoldForParentConfirmation(toDelete, pruneRatio)
        } else {
            PruneDecision.PruneImmediately(toDelete)
        }
    }

    @Test
    fun testAmbiguousEmptyCatalogKeepsLocalLibraryIntact() {
        val local = listOf("v1", "v2", "v3", "v4")
        val incoming = emptyList<String>()

        val decision = evaluatePruneGuard(
            localVideoIds = local,
            incomingVideoIds = incoming,
            isCatalogClearedExplicitly = false
        )

        assertEquals(PruneDecision.KeepLocalLibrary, decision)
    }

    @Test
    fun testExplicitClearedSignalHoldsForParentConfirmation() {
        val local = listOf("v1", "v2", "v3", "v4")
        val incoming = emptyList<String>()

        val decision = evaluatePruneGuard(
            localVideoIds = local,
            incomingVideoIds = incoming,
            isCatalogClearedExplicitly = true,
            allowMassPrune = false
        )

        assertTrue(decision is PruneDecision.HoldForParentConfirmation)
        val hold = decision as PruneDecision.HoldForParentConfirmation
        assertEquals(4, hold.videoIds.size)
        assertEquals(1.0, hold.pruneRatio, 0.001)
    }

    @Test
    fun testNormalIncrementalPruneUnderFiftyPercent() {
        val local = listOf("v1", "v2", "v3", "v4")
        // Only v4 removed (1/4 = 25% <= 50%)
        val incoming = listOf("v1", "v2", "v3", "v5")

        val decision = evaluatePruneGuard(
            localVideoIds = local,
            incomingVideoIds = incoming,
            isCatalogClearedExplicitly = false
        )

        assertTrue(decision is PruneDecision.PruneImmediately)
        val prune = decision as PruneDecision.PruneImmediately
        assertEquals(listOf("v4"), prune.videoIds)
    }

    @Test
    fun testSafetyCapTriggersWhenDeletionsExceedFiftyPercent() {
        val local = listOf("v1", "v2", "v3", "v4", "v5")
        // 4 of 5 deleted (80% > 50%)
        val incoming = listOf("v1")

        val decision = evaluatePruneGuard(
            localVideoIds = local,
            incomingVideoIds = incoming,
            isCatalogClearedExplicitly = false,
            allowMassPrune = false
        )

        assertTrue(decision is PruneDecision.HoldForParentConfirmation)
        val hold = decision as PruneDecision.HoldForParentConfirmation
        assertEquals(4, hold.videoIds.size)
        assertEquals(0.80, hold.pruneRatio, 0.001)
        assertTrue(hold.videoIds.containsAll(listOf("v2", "v3", "v4", "v5")))
    }

    @Test
    fun testConfirmedMassPruneAllowsDeletion() {
        val local = listOf("v1", "v2", "v3", "v4", "v5")
        val incoming = listOf("v1")

        val decision = evaluatePruneGuard(
            localVideoIds = local,
            incomingVideoIds = incoming,
            isCatalogClearedExplicitly = false,
            allowMassPrune = true // Parent explicitly confirmed!
        )

        assertTrue(decision is PruneDecision.PruneImmediately)
        val prune = decision as PruneDecision.PruneImmediately
        assertEquals(4, prune.videoIds.size)
    }
}
