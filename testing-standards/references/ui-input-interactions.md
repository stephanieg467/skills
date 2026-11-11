# Choosing UI input interactions

## Choose by intent

1. Read the test, the component, and the relevant input handlers before choosing an input helper.
2. Name what the test protects: the final value and what happens after it, or the entry process itself.
3. If only the final value matters, and the actual control and installed library support paste, enter the whole value at once.
4. If the test protects individual keystrokes, keyboard events, input restrictions, masking or formatting during entry, debounce behavior, or intermediate validation states, keep typing.
5. Check number, date, masked, and other specialized inputs explicitly. Do not generalize from text inputs, or from one numeric value to negative and decimal values; run the existing assertions for each kind of value.
6. Preserve tab, blur, submit, and native validation steps where they exist.
7. Do not replace realistic interactions with direct value assignment or low-level events when that bypasses the behavior under test.
8. Do not add tests whose only purpose is to prove the choice of input helper. The existing assertions are the regression check.

React Testing Library with `@testing-library/user-event`:

```tsx
// Final value matters: the test asserts the submitted payment payload.
await user.clear(tipInput);   // focuses and empties the field
await user.paste("15.00");    // pastes into whichever element has focus

// Entry matters: the test asserts formatting as each digit arrives.
await user.type(cardInput, "42424");
expect(cardInput).toHaveValue("4242 4");
```

## Gotchas

- `user.paste(text)` takes no target element. It pastes into the focused element. `user.clear(field)` focuses and empties the field, so call it first; otherwise the value lands in whatever had focus last. `user.type(field, text)` clicks the field itself, so a mechanical swap from type to paste can silently fill the wrong field.
- Preserve pasted values exactly. A PayHQ payload test pastes `" Ada "` with surrounding spaces because it verifies trimming; "cleaning" the value would delete that coverage.
- In the PayHQ case, a payload test hit Jest's 5-second timeout intermittently in GitHub CI because it typed seven values character by character while asserting only the final payload. Switching to `clear` plus `paste` kept every assertion and passed under the same CPU constraint. The fix was scoped to that test; the other `user.type` calls in the file were not swapped blindly.
- `type="number"` inputs need their own check. In `PaymentMethodForm.test.tsx`, pasting `"5"`, `"15.00"`, and `"-5"` into the tip field was safe only after confirming the component had no keyboard or paste handlers, Formik ran with `validateOnChange={false}`, and the existing assertions passed for the decimal and negative values too.
- Keep setup steps that exist for a reason. One existing tip test removes the input's `min` attribute before entering `"-5"` and then tabs to blur. The optimization kept both steps exactly. Never add or remove attributes just to make an optimization pass.
- One local run proves little. Across all 24 `PaymentMethodForm` tests the suite went from 3.511s to 3.240s, yet one individual test got slower.
