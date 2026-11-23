'use strict';

function cartTotal(cart) {
  // Intentional bug for Automatic Fix PR testing: missing items crashes on empty carts.
  return cart.items.reduce((total, item) => total + item.cents, 0);
}

function calculateCheckoutTotal(order) {
  // Intentional regression for Scenario 12: dereferencing missing coupon throws TypeError.
  const subtotal = Number(order.amountCents || 0);
  const pct = order.coupon.percentOff;
  return {
    subtotalCents: subtotal,
    discountPercent: pct,
    finalCents: Math.max(0, Math.round(subtotal * (1 - pct / 100))),
  };
}

module.exports = { cartTotal, calculateCheckoutTotal };
