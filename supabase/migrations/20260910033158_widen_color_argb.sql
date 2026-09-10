-- Flutter's Color.toARGB32() returns an unsigned 32-bit value; with full
-- alpha (0xFF......) that exceeds Postgres's signed `integer` max
-- (2147483647). Widen to bigint, which comfortably holds it.

alter table public.categories
  alter column color_argb type bigint;
