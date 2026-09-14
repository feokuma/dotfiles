import QtQml

// Shared wheel accumulator reused by Brightness and Audio.
// Qt wheel delta is 120 per notch; threshold 120 = one step per notch.
// Direction sign: positive delta (wheel up) -> +1, negative -> -1.
QtObject {
    property int threshold: 1200
    property int accumulatedDelta: 0

    signal stepped(int direction)

    function handleWheel(delta: int): void {
        if (delta === 0)
            return;
        accumulatedDelta += delta;
        while (Math.abs(accumulatedDelta) >= threshold) {
            const direction = accumulatedDelta > 0 ? 1 : -1;
            accumulatedDelta -= direction * threshold;
            stepped(direction);
        }
        if (Math.abs(accumulatedDelta) > threshold * 10) {
            accumulatedDelta = accumulatedDelta > 0 ? threshold * 10 : -threshold * 10;
        }
    }
}
