package in.nowaito.rider;

import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/riders")
public class RiderController {

    private final RiderRepository riderRepository;

    public RiderController(RiderRepository riderRepository) {
        this.riderRepository = riderRepository;
    }

    @GetMapping("/{id}")
    public Rider get(@PathVariable UUID id) {
        return riderRepository.findById(id).orElseThrow();
    }

    @PostMapping
    public Rider create(@RequestBody Rider rider) {
        return riderRepository.save(rider);
    }
}
