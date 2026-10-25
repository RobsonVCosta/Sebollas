// Live WebMSX regression: browser keyboard and selected scene checkpoints.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require('playwright-core');
const root = path.resolve(__dirname, '..');
const rom = fs.readFileSync(path.join(root, 'Sebollas.rom'));
(async () => {
    const browser = await chromium.launch({
        executablePath: process.env.CHROME_PATH || '/usr/bin/google-chrome', headless: true,
        args: ['--no-sandbox', '--disable-dev-shm-usage', '--autoplay-policy=no-user-gesture-required'],
    });
    try {
        for (const machine of ['MSX2PA', 'MSX2PE']) {
            const page = await browser.newPage({viewport: {width: 1100, height: 900}, ignoreHTTPSErrors: true});
            const errors = [];
            page.on('pageerror', error => errors.push(error.message));
            await page.goto(`https://webmsx.org/?M=${machine}`, {waitUntil: 'domcontentloaded', timeout: 60000});
            await page.waitForFunction(() => window.WMSX?.room?.machine && !WMSX.room.isLoading, null, {timeout: 60000});
            const frames = n => page.evaluate(n => {WMSX.room.runFramesAtTopSpeed(n); WMSX.room.mainVideoClock.pause();}, n);
            const read = address => page.evaluate(a => WMSX.room.machine.bus.read(a), address);
            const memory = (address, length) => page.evaluate(({address, length}) => Array.from({length}, (_, i) => WMSX.room.machine.bus.read(address + i)), {address, length});
            const write = writes => page.evaluate(writes => {
                for (const [address, value] of Object.entries(writes)) WMSX.room.machine.bus.write(Number(address), value);
            }, writes);
            const wait = async predicate => {
                for (let i = 0; i < 2000; i++) {if (await predicate()) return; await frames(1);}
                throw new Error('Timed out waiting for the game state');
            };
            const shot = name => page.locator('canvas').first().screenshot({path: path.join(root, `previews/${name}-webmsx-${machine}.png`)});
            const intro = async stage => {
                await wait(async () => await read(0xC000) === 10 && await read(0xC060) === stage && await read(0xC063) >= 235);
                await frames(5);
                assert.equal(await read(0xFCAF), 8);
                await shot(`intro-${stage}`);
                await wait(async () => await read(0xC000) === 1);
                await frames(5);
                assert.equal(await read(0xC060), stage);
                assert.equal(await read(0xC006), 5, 'five lives at the start of every stage');
                const route = fs.readFileSync(path.join(root, `resources/generated/route${stage}.bin`));
                assert.deepEqual(await memory(0xD000, 64), [...route.subarray(0, 64)], 'active route in RAM');
                assert.deepEqual(await memory(0xE400, 16), [...route.subarray(5120, 5136)], 'road centers in RAM');
                assert.equal(await read(0xFCAF), 4);
            };
            const endRoad = async () => {
                await write({[0xC017]: 0, [0xC004]: 120, [0xC005]: 80, [0xC061]: 1,
                    [0xC020]: 0, [0xC028]: 0, [0xC030]: 0, [0xC053]: 0, [0xC04E]: 100});
            };
            const format = await page.evaluate(data => {
                const bytes = Uint8Array.from(atob(data), c => c.charCodeAt(0));
                const slot = wmsx.SlotCreator.createFromROM(new wmsx.ROM('Sebollas.rom', bytes));
                WMSX.room.machine.getCartridgeSocket().insertCartridge(slot, 0, true);
                WMSX.room.machine.powerOn(); WMSX.room.machine.reset();
                return slot.format.name;
            }, rom.toString('base64'));
            assert.equal(format, 'ASCII8');
            await frames(1000);
            assert.equal(await read(0xC000), 0);
            await page.locator('canvas').first().click();
            await page.keyboard.down('Space'); await frames(10); await page.keyboard.up('Space');
            await intro(0);
            assert.deepEqual(await memory(0x6000, 16), [...rom.subarray(0x2000, 0x2010)], 'fixed second code bank');
            assert.equal(await read(0xC061), 0, 'fishing waits for interaction');
            await shot('fishing-gameplay');
            await page.keyboard.down('ArrowDown'); await frames(35); await page.keyboard.up('ArrowDown');
            assert.equal(await read(0xC005), 152, 'player can descend to Y=152');
            await page.keyboard.down('Space'); await frames(3); await page.keyboard.up('Space');
            assert.equal(await read(0xC059), 0, 'no horn while walking');
            await write({[0xC020]: 1, [0xC021]: 112, [0xC022]: 110, [0xC023]: 0,
                [0xC026]: 0, [0xC027]: 0, [0xC004]: 112, [0xC005]: 128, [0xC018]: 255});
            await frames(3);
            assert.ok(await read(0xC026) > 0, 'nearby cow starts pursuing');
            await shot('cow-chase');
            for (const key of ['ArrowLeft','ArrowUp','ArrowRight','ArrowDown','ArrowLeft','ArrowUp','ArrowRight','ArrowDown']) {
                await page.keyboard.down(key); await frames(40); await page.keyboard.up(key);
            }
            assert.equal(await read(0xC026), 0, 'cow gives up after five seconds');
            await write({[0xC020]: 0, [0xC018]: 255, [0xC017]: 94, [0xC004]: 168,
                [0xC005]: 128, [0xC04E]: 40, [0xC016]: 7});
            await frames(15);
            assert.ok(await read(0xC04E) > 40, 'fishing restores hunger');
            await shot('fishing-deck');
            await endRoad();
            await write({[0xC005]: 152}); await frames(5);
            assert.equal(await read(0xC000), 1, 'destination requires touching the boy');
            for (const [row, y] of [[10,16], [9,24], [4,64], [0,96]]) {
                await write({[0xC017]: row, [0xC016]: 0}); await frames(2);
                assert.equal(await read(0xC09D), y, 'boy follows the world scroll');
            }
            await write({[0xC004]: await read(0xC066), [0xC005]: 96});
            await wait(async () => await read(0xC000) === 11);
            assert.equal(await read(0xC069), 0, 'first garapa encounter is peaceful');
            await frames(5); await shot('peaceful-garapa');
            await intro(1);
            await endRoad();
            await wait(async () => await read(0xC000) === 12);
            assert.equal(await read(0xC065), 0, 'no enemy health to attack');
            await page.keyboard.down('Space'); await frames(3); await page.keyboard.up('Space');
            assert.equal(await read(0xC059), 0);
            await write({[0xC069]: 1, [0xC06A]: 120, [0xC06B]: 126, [0xC004]: 112, [0xC005]: 128, [0xC020]: 0});
            await frames(5);
            assert.ok(await read(0xC058) > 0, 'canes are collectible');
            await shot('cane-collection');
            await write({[0xC004]: 216, [0xC005]: 136, [0xC04E]: 30});
            await frames(15);
            assert.ok(await read(0xC04E) > 30, 'fishing deck also works during cane collection');
            await shot('cane-fishing-deck');
            await write({[0xC063]: 208, [0xC064]: 7}); await frames(5);
            assert.equal(await read(0xC0AC), 3, 'herd grows to three cows');
            await shot('cane-three-cows');
            await write({[0xC09A]: 99, [0xC058]: 0x99, [0xC069]: 1, [0xC06A]: 120,
                [0xC06B]: 126, [0xC004]: 112, [0xC005]: 128, [0xC020]: 0, [0xC028]: 0, [0xC030]: 0});
            await frames(5);
            assert.equal(await read(0xC09A), 100, '100th cane completes the objective');
            await shot('cane-goal-complete');
            await wait(async () => await read(0xC000) === 7);
            await intro(2);
            await shot('car-to-bar');
            await page.keyboard.down('Space'); await frames(2); await page.keyboard.up('Space');
            assert.equal(await read(0xC059), 1, 'car horn returns');
            await endRoad();
            await wait(async () => await read(0xC000) === 11);
            assert.equal(await read(0xC060), 2, 'bar arrival, with no boss');
            await frames(5); await shot('bar-arrival');
            await intro(3);
            await endRoad();
            await wait(async () => await read(0xC000) === 4);
            assert.equal(await read(0xC065), 12, 'final cheese boss');
            await wait(async () => await read(0xC069) === 1);
            await frames(8); await shot('cheese-final-boss');
            await write({[0xC004]: 216, [0xC005]: 136, [0xC04E]: 30});
            await frames(15);
            assert.ok(await read(0xC04E) > 30, 'final arena refueling');
            await shot('final-arena-station');
            await write({[0xC065]: 1, [0xC004]: await read(0xC066)});
            await page.keyboard.down('Space'); await wait(async () => await read(0xC090) === 1); await page.keyboard.up('Space');
            await wait(async () => await read(0xC000) === 5);
            await wait(async () => await read(0xC06E) === 3);
            const boys = await memory(0xC072, 3); await frames(60);
            assert.deepEqual(await memory(0xC072, 3), boys);
            await wait(async () => await read(0xC06E) === 5);
            await shot('boys-chasing');
            await wait(async () => await read(0xC000) === 8 && await read(0xC063) < 250 && await read(0xC063) > 230);
            await shot('ending-1');
            await wait(async () => await read(0xC000) === 9 && await read(0xC063) < 250 && await read(0xC063) > 230);
            await shot('ending-2');
            await wait(async () => await read(0xC000) === 6);
            await frames(500); await shot('credits');
            assert.deepEqual(errors, []);
            console.log(`PASS WebMSX ${machine}: ASCII8, four introductions, walking trio, five lives, chase expiry, hunger/decks, canes, bar, final cheese boss, ending and credits`);
            await page.close();
        }
    } finally {await browser.close();}
})().catch(error => {console.error(error); process.exitCode = 1;});
