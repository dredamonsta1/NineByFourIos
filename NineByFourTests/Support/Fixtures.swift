import Foundation

// Real API responses, captured 2026-10-30 and trimmed to one album each.
// Decoding tests run against these so a model that drifts from what the
// server actually sends fails here, not silently in the app.
enum Fixtures {
    /// GET /api/artists/85 (Michael Jackson)
    static let artistDetail = #"""
{
 "artist": {
  "artist_id": 85,
  "artist_name": "Michael Jackson",
  "aka": "King of Pop",
  "genre": "Pop / R&B",
  "count": 5,
  "state": "Indiana",
  "region": "Midwest",
  "label": "Epic / Sony",
  "image_url": "https://i.scdn.co/image/ab6761610000e5eb997cc9a4aec335d46c9481fd",
  "last_enriched_at": "2026-04-05T17:01:20.848Z",
  "website_url": null,
  "merch_url": null,
  "newsletter_url": null,
  "spotify_url": "https://open.spotify.com/artist/3fMbdgg4jU18AjLCKBhRSm",
  "apple_music_url": null,
  "stripe_charges_enabled": false,
  "stripe_payouts_enabled": false,
  "commerce_enabled": false,
  "eligible_for_news_tagging": false,
  "featured_video_id": "h_D3VFfhvs4",
  "featured_video_fetched_at": "2026-06-24T15:00:50.016Z",
  "soundcloud_url": null,
  "musicbrainz_id": null,
  "musicbrainz_checked_at": null,
  "listenbrainz_checked_at": null,
  "is_verified": false,
  "albums": [
   {
    "album_id": 408,
    "artist_id": 85,
    "album_name": "Invincible",
    "year": 2001,
    "certifications": "2x Platinum",
    "album_image_url": "https://i.scdn.co/image/ab67616d00001e0276bfd700e0c47fae7f2c7b75",
    "release_date": null,
    "spotify_url": null,
    "apple_music_url": null,
    "price_cents": null,
    "download_enabled": false,
    "audio_cloudinary_public_id": null,
    "audio_format": null,
    "release_type": "album",
    "created_at": null,
    "tracks_checked_at": null,
    "apple_collection_id": "215738269",
    "apple_samples": null,
    "samples_checked_at": "2026-10-07T17:27:03.731727+00:00",
    "deezer_album_id": null
   }
  ],
  "singles": [],
  "members": [],
  "groups": [
   {
    "artist_id": 117423,
    "artist_name": "The Jackson 5",
    "image_url": "https://cdn-images.dzcdn.net/images/artist/2e5ab9758b5e69a147d226d9f1c61108/1000x1000-000000-80-0-0.jpg"
   }
  ]
 }
}
"""#

    /// GET /api/artists?limit=1
    static let artistList = #"""
{
 "artists": [
  {
   "artist_id": 85,
   "artist_name": "Michael Jackson",
   "aka": "King of Pop",
   "genre": "Pop / R&B",
   "count": 5,
   "state": "Indiana",
   "region": "Midwest",
   "label": "Epic / Sony",
   "image_url": "https://i.scdn.co/image/ab6761610000e5eb997cc9a4aec335d46c9481fd",
   "last_enriched_at": "2026-04-05T17:01:20.848Z",
   "website_url": null,
   "merch_url": null,
   "newsletter_url": null,
   "spotify_url": "https://open.spotify.com/artist/3fMbdgg4jU18AjLCKBhRSm",
   "apple_music_url": null,
   "stripe_charges_enabled": false,
   "stripe_payouts_enabled": false,
   "commerce_enabled": false,
   "eligible_for_news_tagging": false,
   "featured_video_id": "h_D3VFfhvs4",
   "featured_video_fetched_at": "2026-06-24T15:00:50.016Z",
   "soundcloud_url": null,
   "musicbrainz_id": null,
   "musicbrainz_checked_at": null,
   "listenbrainz_checked_at": null,
   "is_verified": false,
   "albums": [
    {
     "album_id": 408,
     "artist_id": 85,
     "album_name": "Invincible",
     "year": 2001,
     "certifications": "2x Platinum",
     "album_image_url": "https://i.scdn.co/image/ab67616d00001e0276bfd700e0c47fae7f2c7b75",
     "release_date": null,
     "spotify_url": null,
     "apple_music_url": null,
     "price_cents": null,
     "download_enabled": false,
     "audio_cloudinary_public_id": null,
     "audio_format": null,
     "release_type": "album",
     "created_at": null,
     "tracks_checked_at": null,
     "apple_collection_id": "215738269",
     "apple_samples": null,
     "samples_checked_at": "2026-10-07T17:27:03.731727+00:00",
     "deezer_album_id": null
    }
   ]
  }
 ],
 "count_is_estimate": true,
 "page": 1,
 "limit": 1,
 "totalCount": 112582,
 "totalPages": 112582,
 "hasMore": true
}
"""#

    static func data(_ json: String) -> Data { Data(json.utf8) }
}
