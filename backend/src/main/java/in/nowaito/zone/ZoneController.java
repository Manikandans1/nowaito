package in.nowaito.zone;

import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/zones")
public class ZoneController {

    private final ZoneRepository zoneRepository;
    private final ZoneService zoneService;

    public ZoneController(ZoneRepository zoneRepository, ZoneService zoneService) {
        this.zoneRepository = zoneRepository;
        this.zoneService = zoneService;
    }

    @GetMapping
    public List<Zone> all() {
        return zoneRepository.findAll();
    }

    @PostMapping
    public Zone create(@RequestBody Zone zone) {
        return zoneRepository.save(zone);
    }

    @GetMapping("/health")
    public List<ZoneService.ZoneHealth> health() {
        return zoneService.allZoneHealth();
    }

    @GetMapping("/{id}/health")
    public ZoneService.ZoneHealth healthOne(@PathVariable UUID id) {
        Zone zone = zoneRepository.findById(id).orElseThrow();
        return zoneService.health(zone);
    }
}
