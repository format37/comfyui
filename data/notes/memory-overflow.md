Plan: Fix RAM Overflow in WanVideo Workflow

 Problem: Workflow processes all 501 frames simultaneously without chunking, causing ~50GB peak memory usage and OOM kills.

 Solution: Apply 3 critical fixes to the workflow JSON:

 Changes to data/workflows/Wan22Animate_ArtModified.json:

 1. Connect context chunking (Node 110 → Node 27)
   - Wire Node 110 (WanVideoContextOptions) output to Node 27 (WanVideoSampler) input slot #5
   - This enables processing in 81-frame chunks instead of all frames at once
   - Expected: 70-85% memory reduction
 2. Enable VAE tiling (Node 28)
   - Change widgets_values[0] from false to true in WanVideoDecode node
   - Processes video in 272×272 tiles during decode
   - Expected: 50-70% memory reduction during decode phase
 3. Fix frame count (Node 62)
   - Change widgets_values[2] from 501 to 193 in WanVideoAnimateEmbeds node
   - Matches your intended frame count
   - Expected: 60% memory reduction proportional to frame count

 Expected Outcome:

 - Before: ~50GB peak memory → OOM kill
 - After: ~4-6GB peak memory → Should run successfully on your GPU