# Continue after compaction

Automatically resumes unfinished work after manual or threshold-triggered Pi
context compaction.

The extension does not enqueue a second continuation during context-overflow
recovery: Pi already retries the interrupted turn in that case. Compaction IDs
are deduplicated, pending callbacks are cancelled during session replacement or
reload, and persisted JSONL is treated as a fallback rather than mandatory
input.
