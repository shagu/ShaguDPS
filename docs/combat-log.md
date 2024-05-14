# World of Warcraft: Combat Log - Events & Strings

An overview of World of Warcraft 1.12.1 (Vanilla) combat log events and the related global strings they can produce.
The goal of this list is to identify which strings can be fired by which event as accurate as possible. Some events
might overlap with other strings, and some strings might be used across several events, which is why there are clusters.

The list might be incomplete and faulty. If you came here and found mistakes, please let me know or send a PR.

## Damage

### Hit Damage

#### Hit Damage (self vs. other)

- Events:
  - `CHAT_MSG_COMBAT_SELF_HITS`

- Strings:
  - `COMBATHITSELFOTHER`
  - `COMBATHITSCHOOLSELFOTHER`
  - `COMBATHITCRITSELFOTHER`
  - `COMBATHITCRITSCHOOLSELFOTHER`


#### Hit Damage (other vs. self)

- Events:
  - `CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS`

- Strings:
  - `COMBATHITOTHERSELF`
  - `COMBATHITCRITOTHERSELF`
  - `COMBATHITSCHOOLOTHERSELF`
  - `COMBATHITCRITSCHOOLOTHERSELF`


#### Hit Damage (other vs. other)

- Events:
  - `CHAT_MSG_COMBAT_PARTY_HITS`
  - `CHAT_MSG_COMBAT_FRIENDLYPLAYER_HITS`
  - `CHAT_MSG_COMBAT_HOSTILEPLAYER_HITS`
  - `CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_HITS`
  - `CHAT_MSG_COMBAT_CREATURE_VS_PARTY_HITS`
  - `CHAT_MSG_COMBAT_PET_HITS`

- Strings:
  - `COMBATHITOTHEROTHER`
  - `COMBATHITCRITOTHEROTHER`
  - `COMBATHITSCHOOLOTHEROTHER`
  - `COMBATHITCRITSCHOOLOTHEROTHER`


### Spell Damage

#### Spell Damage (self vs. self/other)

- Events:
  - `CHAT_MSG_SPELL_SELF_DAMAGE`

- Strings:
  - `SPELLLOGSCHOOLSELFSELF`
  - `SPELLLOGCRITSCHOOLSELFSELF`
  - `SPELLLOGSELFSELF`
  - `SPELLLOGCRITSELFSELF`
  - `SPELLLOGSCHOOLSELFOTHER`
  - `SPELLLOGCRITSCHOOLSELFOTHER`
  - `SPELLLOGSELFOTHER`
  - `SPELLLOGCRITSELFOTHER`


#### Spell Damage (other vs. self)

- Events:
  - `CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE`

- Strings:
  - `SPELLLOGSCHOOLOTHERSELF`
  - `SPELLLOGCRITSCHOOLOTHERSELF`
  - `SPELLLOGOTHERSELF`
  - `SPELLLOGCRITOTHERSELF`


#### Spell Damage (other vs. other)

- Events:
  - `CHAT_MSG_SPELL_PARTY_DAMAGE`
  - `CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE`
  - `CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE`
  - `CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE`
  - `CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE`
  - `CHAT_MSG_SPELL_PET_DAMAGE`

- Strings:
  - `SPELLLOGSCHOOLOTHEROTHER`
  - `SPELLLOGCRITSCHOOLOTHEROTHER`
  - `SPELLLOGOTHEROTHER`
  - `SPELLLOGCRITOTHEROTHER`


### Shield Damage

#### Shield Damage (self vs. other)

- Events:
  - `CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF`

- Strings:
  - `DAMAGESHIELDSELFOTHER`


#### Shield Damage (other vs. other)

- Events:
  - `CHAT_MSG_SPELL_DAMAGESHIELDS_ON_OTHERS`

- Strings:
  - `DAMAGESHIELDOTHEROTHER`


#### Shield Damage (other vs. self)

- Events:
  - `CHAT_MSG_SPELL_DAMAGESHIELDS_ON_OTHERS`

- Strings:
  - `DAMAGESHIELDOTHERSELF`


### Periodic Damage

#### Periodic Damage (self/other vs. other)

- Events:
   - `CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE`
   - `CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE`
   - `CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE`
   - `CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE`

- Strings:
  - `PERIODICAURADAMAGEOTHEROTHER`
  - `PERIODICAURADAMAGESELFOTHER`


#### Periodic Damage (self/other vs. self)

- Events:
   - `CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE`

- Strings:
  - `PERIODICAURADAMAGEOTHERSELF`
  - `PERIODICAURADAMAGESELFSELF`


## Heal

### Heal

#### Heal (self vs. self/other)

- Events:
  - `CHAT_MSG_SPELL_SELF_BUFF`

- Strings:
  - `HEALEDCRITSELFSELF`
  - `HEALEDSELFSELF`
  - `HEALEDCRITSELFOTHER`
  - `HEALEDSELFOTHER`


#### Heal (other vs. self/other)

- Events:
  - `CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF`
  - `CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF`
  - `CHAT_MSG_SPELL_PARTY_BUFF`

- Strings:
  - `HEALEDCRITOTHEROTHER`
  - `HEALEDOTHEROTHER`
  - `HEALEDCRITOTHERSELF`
  - `HEALEDOTHERSELF`


### Periodic Heal

#### Periodic Heal (self/other vs. other)

- Events:
  - `CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS`
  - `CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS`
  - `CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS`

- Strings:
  - `PERIODICAURAHEALOTHEROTHER`
  - `PERIODICAURAHEALSELFOTHER`


#### Periodic Heal (other vs. self/other)

- Events:
  - `CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS`

- Strings:
  - `PERIODICAURAHEALSELFSELF`
  - `PERIODICAURAHEALOTHERSELF`
