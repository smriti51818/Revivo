# Produce seed images

These photos are uploaded to S3 (the uploads bucket) by `scripts/seed_listings.py`
and referenced from each seeded listing via its `imageKey`. This is why demo
listings show real, correct produce photos instead of random placeholders.

## How it works
- Filename → vegetable: the file's base name (lower-case, `_` for spaces) is
  matched to the listing's vegetable. e.g. `bell_pepper.jpg` → "Bell Pepper".
- On seed, each image is uploaded once to `uploads/seed/<slug>.jpg` and the key
  is stored on every listing of that vegetable. No `imageUrl` is stored, so the
  presigned URL is always regenerated from the key (and edits reflect instantly).

## Replacing an image
Drop a JPEG here named after the vegetable (all lower-case, spaces → `_`):

    tomato.jpg  carrot.jpg  spinach.jpg  bell_pepper.jpg  cauliflower.jpg  beans.jpg

Then re-run from `backend/` with the venv active:

    python scripts/seed_listings.py

A vegetable with no matching file simply seeds without a photo (the app shows
its tinted placeholder).
