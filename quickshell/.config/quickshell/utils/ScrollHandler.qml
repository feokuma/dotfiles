import QtQml

// Shared wheel accumulator reused by Brightness and Audio.
// Qt wheel delta is 120 per notch; threshold 120 = one step per notch.
// Direction sign: positive delta (wheel up) -> +1, negative -> -1.
QtObject {
    property int threshold: 120
    property int accumulatedDelta: 0

    signal stepped(int direction)

    function handleWheel(delta: int): void {
        if (delta === 0)
            return;
        if (accumulatedDelta !== 0 && Math.sign(accumulatedDelta) !== Math.sign(delta))
            accumulatedDelta = 0;
        accumulatedDelta += delta;
        if (Math.abs(accumulatedDelta) < threshold)
            return;
        const direction = accumulatedDelta > 0 ? 1 : -1;
        accumulatedDelta -= direction * threshold;
        stepped(direction);
    }
}
