# Restart

## DOING

- **Molt 1.4.5, handed to hv for the cut:** 0093 to 0098 merged at 4116a1b and closed at ca6a273, molt-dc's landing END at 24ae78e, vc's dry run clean there. Write freeze in Molt's checkout until hv has pushed: read HEAD with `GIT_OPTIONAL_LOCKS=0 git log -1` before any write, and write nothing while a `release: v1.4.5` commit has no pushed tag.

## TODO

- **After the cut:** read CI on the pushed head, tell pipeliner-dc that brew has 1.4.5 (vc todo 47), then the rollout to the other sleeves (vc todo 44).
