local _, addon = ...

local tracker = {}
addon.tracker = tracker

function tracker:Clear()
    if not self.seal then return end
    self.seal, self.count, self.expires, self.highest, self.estimated = nil, nil, nil, nil, nil
end

function tracker:Expire(now)
    if self.seal and now >= self.expires then
        self:Clear()
    end
end

function tracker:Set(seal, count, expires, estimated, audible)
    local previous = self.seal == seal and self.highest or 0
    self.seal, self.count, self.expires, self.estimated = seal, count, expires, estimated
    self.highest = math.max(previous, count)
    if audible and count > previous then
        addon.PlayAlert(seal, count)
    end
end

function tracker:Observe(seal, count, expires, now, refresh, audible, estimated)
    self:Expire(now)
    if not expires then
        local unchanged = self.seal == seal and self.count == count and not refresh
        expires = unchanged and self.expires or now + addon.echoDuration
    end
    if self.seal ~= seal or self.count ~= count or self.expires ~= expires or self.estimated ~= estimated then
        self:Set(seal, count, expires, estimated, audible)
        return true
    end
end

function tracker:Hit(seal, now)
    self:Expire(now)
    if self.seal and self.seal ~= seal then
        self:Clear()
    elseif seal.echo then
        local count = math.min((self.count or 0) + 1, addon.maxStacks)
        self:Set(seal, count, now + addon.echoDuration, true, true)
    end
end
