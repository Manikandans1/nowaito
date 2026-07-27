package in.nowaito.payment;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.UUID;

/**
 * Razorpay never charges a platform fee to integrate — only a small % per
 * real transaction — so this works at ₹0 budget already. Use Razorpay's
 * free TEST MODE keys (rzp_test_...) for the entire pilot; switch to live
 * keys only once you're processing real rider payments.
 * <p>
 * Flow matches the business doc exactly:
 *  1. preAuthorize() at booking — places a hold for lockedFare + guaranteeFee, doesn't deduct yet.
 *  2. capture() at drop-off — converts that hold into an actual charge.
 *  3. release() — used if a trip is cancelled before completion, releases the hold with no charge.
 */
@Service
public class PaymentService {

    @Value("${nowaito.razorpay.key-id}")
    private String keyId;

    @Value("${nowaito.razorpay.key-secret:}")
    private String keySecret;

    public record PaymentIntent(String intentId, int amountRupees, String status) {}

    public PaymentIntent preAuthorize(UUID tripId, int amountRupees) {
        // TODO: replace with a real Razorpay Orders API call:
        //   POST https://api.razorpay.com/v1/orders  { amount: amountRupees*100, currency: "INR" }
        // using keyId/keySecret as HTTP Basic auth. Store the returned order id as intentId.
        String mockIntentId = "order_mock_" + tripId;
        return new PaymentIntent(mockIntentId, amountRupees, "AUTHORIZED");
    }

    public PaymentIntent capture(String intentId, int amountRupees) {
        // TODO: replace with Razorpay Payments capture API call using the payment id
        // collected client-side after the pre-auth, once you're past the sandbox stage.
        return new PaymentIntent(intentId, amountRupees, "CAPTURED");
    }

    public PaymentIntent release(String intentId) {
        return new PaymentIntent(intentId, 0, "RELEASED");
    }
}
