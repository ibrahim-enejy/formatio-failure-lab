export interface Coupon {
  code: string;
  percentOff: number;
}

export interface CheckoutInput {
  amountCents?: number;
  coupon?: Coupon;
}

export interface CheckoutResult {
  subtotalCents: number;
  discountCents: number;
  totalCents: number;
}

/**
 * Scenario 12: Deliberate 1-line regression for suspect-commit attribution.
 * Passing `{ amountCents: 4900 }` without `coupon` throws a TypeError reading
 * `coupon.percentOff`, giving Formatio's AI error advisor and autonomous fix PR
 * an unmistakable frame and minimal patch target.
 */
export function calculateCheckoutTotal(input: CheckoutInput): CheckoutResult {
  const subtotalCents = Math.max(0, Math.round(input.amountCents ?? 4900));
  const discountRate = input.coupon!.percentOff / 100;
  const discountCents = Math.round(subtotalCents * discountRate);
  return {
    subtotalCents,
    discountCents,
    totalCents: Math.max(0, subtotalCents - discountCents),
  };
}
