# seed/ — demo data

Scripts that populate the deployed backend with the pilot personas used in the demo narrative
(see [`../docs/demo-script.md`](../docs/demo-script.md)).

- **Vendors:** Rajesh + 14 Gandhipuram vendors
- **Buyers:** Hotel Annapoorna + 9 nearby hotels
- **Cook:** Shiva Temple kitchen
- **Volunteer:** local NSS unit
- **Listings:** seeded tomatoes/potatoes/spinach across freshness bands

```bash
make seed   # runs seed_all.py against the deployed stack
```
