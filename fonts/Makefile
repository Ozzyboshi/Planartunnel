ALPHABET := 0 1 2 3 4 5 6 7 8 9 duepunti puntovirgola minore uguale maggiore puntointerrogativo chiocciola a b c d e f g h i j k l m n o p q r s t u v w x y z



all: $(ALPHABET)

$(ALPHABET):
	@echo "Converting letter $@"
	@ilbm2raw -f "$@.iff" "$@.raw" 1>/dev/null 2>/dev/null
	@dd if="$@.raw" of="$@_reduced.raw" bs=2 skip=0 count=1 status=none
	@dd if="$@.raw" of="$@_reduced.raw" bs=1 skip=2 count=1 seek=1 conv=notrunc status=none
	@dd if="$@.raw" of="$@_reduced.raw" bs=1 skip=4 count=1 seek=2 conv=notrunc status=none
	@dd if="$@.raw" of="$@_reduced.raw" bs=1 skip=6 count=1 seek=3 conv=notrunc status=none
	@dd if="$@.raw" of="$@_reduced.raw" bs=1 skip=8 count=1 seek=4 conv=notrunc status=none
	@dd if="$@.raw" of="$@_reduced.raw" bs=1 skip=10 count=1 seek=5 conv=notrunc status=none

	cat "$@_reduced.raw" >> fonts.raw

