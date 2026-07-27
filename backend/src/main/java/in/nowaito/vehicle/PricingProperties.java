package in.nowaito.vehicle;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.Map;

@Component
@ConfigurationProperties(prefix = "nowaito.pricing")
public class PricingProperties {

    /** Guarantee fee per vehicle tier, in rupees. Configurable via application.yml. */
    private Map<VehicleType, Integer> guaranteeFee = new HashMap<>();

    public Map<VehicleType, Integer> getGuaranteeFee() {
        return guaranteeFee;
    }

    public void setGuaranteeFee(Map<VehicleType, Integer> guaranteeFee) {
        this.guaranteeFee = guaranteeFee;
    }

    public int feeFor(VehicleType type) {
        return guaranteeFee.getOrDefault(type, 9);
    }
}
