globalThis.process ??= {};
globalThis.process.env ??= {};
import { i as manifest, n as App, r as DefaultFetchHandler } from "./chunks/entrypoints_C1oQCFDk.mjs";
import "./chunks/image-binding-transform_Bcv1jvfp.mjs";
import "cloudflare:workers";
//#region node_modules/.pnpm/unenv@2.0.0-rc.24/node_modules/unenv/dist/runtime/_internal/utils.mjs
/* @__NO_SIDE_EFFECTS__ */
function createNotImplementedError(name) {
	return /* @__PURE__ */ new Error(`[unenv] ${name} is not implemented yet!`);
}
//#endregion
//#region node_modules/.pnpm/unenv@2.0.0-rc.24/node_modules/unenv/dist/runtime/node/internal/perf_hooks/performance.mjs
var _timeOrigin = globalThis.performance?.timeOrigin ?? Date.now();
var _performanceNow = globalThis.performance?.now ? globalThis.performance.now.bind(globalThis.performance) : () => Date.now() - _timeOrigin;
var nodeTiming = {
	name: "node",
	entryType: "node",
	startTime: 0,
	duration: 0,
	nodeStart: 0,
	v8Start: 0,
	bootstrapComplete: 0,
	environment: 0,
	loopStart: 0,
	loopExit: 0,
	idleTime: 0,
	uvMetricsInfo: {
		loopCount: 0,
		events: 0,
		eventsWaiting: 0
	},
	detail: void 0,
	toJSON() {
		return this;
	}
};
var PerformanceEntry = class {
	__unenv__ = true;
	detail;
	entryType = "event";
	name;
	startTime;
	constructor(name, options) {
		this.name = name;
		this.startTime = options?.startTime || _performanceNow();
		this.detail = options?.detail;
	}
	get duration() {
		return _performanceNow() - this.startTime;
	}
	toJSON() {
		return {
			name: this.name,
			entryType: this.entryType,
			startTime: this.startTime,
			duration: this.duration,
			detail: this.detail
		};
	}
};
var PerformanceMark = class PerformanceMark extends PerformanceEntry {
	entryType = "mark";
	constructor() {
		super(...arguments);
	}
	get duration() {
		return 0;
	}
};
var PerformanceMeasure = class extends PerformanceEntry {
	entryType = "measure";
};
var PerformanceResourceTiming = class extends PerformanceEntry {
	entryType = "resource";
	serverTiming = [];
	connectEnd = 0;
	connectStart = 0;
	decodedBodySize = 0;
	domainLookupEnd = 0;
	domainLookupStart = 0;
	encodedBodySize = 0;
	fetchStart = 0;
	initiatorType = "";
	name = "";
	nextHopProtocol = "";
	redirectEnd = 0;
	redirectStart = 0;
	requestStart = 0;
	responseEnd = 0;
	responseStart = 0;
	secureConnectionStart = 0;
	startTime = 0;
	transferSize = 0;
	workerStart = 0;
	responseStatus = 0;
};
var PerformanceObserverEntryList = class {
	__unenv__ = true;
	getEntries() {
		return [];
	}
	getEntriesByName(_name, _type) {
		return [];
	}
	getEntriesByType(type) {
		return [];
	}
};
var Performance = class {
	__unenv__ = true;
	timeOrigin = _timeOrigin;
	eventCounts = /* @__PURE__ */ new Map();
	_entries = [];
	_resourceTimingBufferSize = 0;
	navigation = void 0;
	timing = void 0;
	timerify(_fn, _options) {
		throw /* @__PURE__ */ createNotImplementedError("Performance.timerify");
	}
	get nodeTiming() {
		return nodeTiming;
	}
	eventLoopUtilization() {
		return {};
	}
	markResourceTiming() {
		return new PerformanceResourceTiming("");
	}
	onresourcetimingbufferfull = null;
	now() {
		if (this.timeOrigin === _timeOrigin) return _performanceNow();
		return Date.now() - this.timeOrigin;
	}
	clearMarks(markName) {
		this._entries = markName ? this._entries.filter((e) => e.name !== markName) : this._entries.filter((e) => e.entryType !== "mark");
	}
	clearMeasures(measureName) {
		this._entries = measureName ? this._entries.filter((e) => e.name !== measureName) : this._entries.filter((e) => e.entryType !== "measure");
	}
	clearResourceTimings() {
		this._entries = this._entries.filter((e) => e.entryType !== "resource" || e.entryType !== "navigation");
	}
	getEntries() {
		return this._entries;
	}
	getEntriesByName(name, type) {
		return this._entries.filter((e) => e.name === name && (!type || e.entryType === type));
	}
	getEntriesByType(type) {
		return this._entries.filter((e) => e.entryType === type);
	}
	mark(name, options) {
		const entry = new PerformanceMark(name, options);
		this._entries.push(entry);
		return entry;
	}
	measure(measureName, startOrMeasureOptions, endMark) {
		let start;
		let end;
		if (typeof startOrMeasureOptions === "string") {
			start = this.getEntriesByName(startOrMeasureOptions, "mark")[0]?.startTime;
			end = this.getEntriesByName(endMark, "mark")[0]?.startTime;
		} else {
			start = Number.parseFloat(startOrMeasureOptions?.start) || this.now();
			end = Number.parseFloat(startOrMeasureOptions?.end) || this.now();
		}
		const entry = new PerformanceMeasure(measureName, {
			startTime: start,
			detail: {
				start,
				end
			}
		});
		this._entries.push(entry);
		return entry;
	}
	setResourceTimingBufferSize(maxSize) {
		this._resourceTimingBufferSize = maxSize;
	}
	addEventListener(type, listener, options) {
		throw /* @__PURE__ */ createNotImplementedError("Performance.addEventListener");
	}
	removeEventListener(type, listener, options) {
		throw /* @__PURE__ */ createNotImplementedError("Performance.removeEventListener");
	}
	dispatchEvent(event) {
		throw /* @__PURE__ */ createNotImplementedError("Performance.dispatchEvent");
	}
	toJSON() {
		return this;
	}
};
var PerformanceObserver = class {
	__unenv__ = true;
	static supportedEntryTypes = [];
	_callback = null;
	constructor(callback) {
		this._callback = callback;
	}
	takeRecords() {
		return [];
	}
	disconnect() {
		throw /* @__PURE__ */ createNotImplementedError("PerformanceObserver.disconnect");
	}
	observe(options) {
		throw /* @__PURE__ */ createNotImplementedError("PerformanceObserver.observe");
	}
	bind(fn) {
		return fn;
	}
	runInAsyncScope(fn, thisArg, ...args) {
		return fn.call(thisArg, ...args);
	}
	asyncId() {
		return 0;
	}
	triggerAsyncId() {
		return 0;
	}
	emitDestroy() {
		return this;
	}
};
var performance = globalThis.performance && "addEventListener" in globalThis.performance ? globalThis.performance : new Performance();
//#endregion
//#region node_modules/.pnpm/@cloudflare+unenv-preset@2.16.2_unenv@2.0.0-rc.24_workerd@1.20261001.1/node_modules/@cloudflare/unenv-preset/dist/runtime/polyfill/performance.mjs
if (!("__unenv__" in performance)) {
	const proto = Performance.prototype;
	for (const key of Object.getOwnPropertyNames(proto)) if (key !== "constructor" && !(key in performance)) {
		const desc = Object.getOwnPropertyDescriptor(proto, key);
		if (desc) Object.defineProperty(performance, key, desc);
	}
}
globalThis.performance = performance;
globalThis.Performance = Performance;
globalThis.PerformanceEntry = PerformanceEntry;
globalThis.PerformanceMark = PerformanceMark;
globalThis.PerformanceMeasure = PerformanceMeasure;
globalThis.PerformanceObserver = PerformanceObserver;
globalThis.PerformanceObserverEntryList = PerformanceObserverEntryList;
globalThis.PerformanceResourceTiming = PerformanceResourceTiming;
//#endregion
//#region \0virtual:astro-cloudflare:config
var sessionKVBindingName = "SESSION";
//#endregion
//#region \0virtual:astro:fetchable
var _virtual_astro_fetchable_default = new DefaultFetchHandler();
//#endregion
//#region node_modules/.pnpm/astro@7.3.5_@types+node@26.6.4_jiti@2.7.0_tsx@4.23.15/node_modules/astro/dist/core/app/entrypoints/virtual/prod.js
var createApp$1 = ({ streaming } = {}) => {
	const app = new App(manifest, streaming);
	app.setFetchHandler(_virtual_astro_fetchable_default);
	return app;
};
//#endregion
//#region node_modules/.pnpm/astro@7.3.5_@types+node@26.6.4_jiti@2.7.0_tsx@4.23.15/node_modules/astro/dist/core/app/entrypoints/virtual/index.js
var createApp = createApp$1;
//#endregion
//#region node_modules/.pnpm/@astrojs+internal-helpers@0.11.0/node_modules/@astrojs/internal-helpers/dist/request.js
function getFirstForwardedValue(multiValueHeader) {
	return multiValueHeader?.toString()?.split(",").map((e) => e.trim())?.[0];
}
var IP_RE = /^[0-9a-fA-F.:]{1,45}$/;
function isValidIpAddress(value) {
	return IP_RE.test(value);
}
function getValidatedIpFromHeader(headerValue) {
	const raw = getFirstForwardedValue(headerValue);
	if (raw && isValidIpAddress(raw)) return raw;
}
//#endregion
//#region node_modules/.pnpm/@astrojs+cloudflare@14.3.3_@types+node@26.6.4_astro@7.3.5_@types+node@26.6.4_jiti@2.7.0_279e0682d3265ea798fa44e48108890d/node_modules/@astrojs/cloudflare/dist/utils/cf-helpers.js
function matchStaticAsset(manifest, requestUrl, env) {
	const { pathname } = new URL(requestUrl);
	if (manifest.assets.has(pathname)) return env.ASSETS.fetch(requestUrl.replace(/\.html$/, ""));
}
async function fallbackToAssets(requestUrl, env) {
	const asset = await env.ASSETS.fetch(requestUrl.replace(/index.html$/, "").replace(/\.html$/, ""));
	if (asset.status !== 404) return asset;
}
function createErrorPageFetch(env) {
	return async (url) => {
		return env.ASSETS.fetch(url.replace(/\.html$/, ""));
	};
}
function createLocals(ctx) {
	const locals = { cfContext: ctx };
	Object.defineProperty(locals, "runtime", {
		enumerable: false,
		value: {
			get env() {
				throw new Error(`Astro.locals.runtime.env has been removed in Astro v6. Use 'import { env } from "cloudflare:workers"' instead.`);
			},
			get cf() {
				throw new Error(`Astro.locals.runtime.cf has been removed in Astro v6. Use 'Astro.request.cf' instead.`);
			},
			get caches() {
				throw new Error(`Astro.locals.runtime.caches has been removed in Astro v6. Use the global 'caches' object instead.`);
			},
			get ctx() {
				throw new Error(`Astro.locals.runtime.ctx has been removed in Astro v6. Use 'Astro.locals.cfContext' instead.`);
			}
		}
	});
	return locals;
}
function getClientAddress(request) {
	return getValidatedIpFromHeader(request.headers.get("cf-connecting-ip"));
}
//#endregion
//#region node_modules/.pnpm/@astrojs+cloudflare@14.3.3_@types+node@26.6.4_astro@7.3.5_@types+node@26.6.4_jiti@2.7.0_279e0682d3265ea798fa44e48108890d/node_modules/@astrojs/cloudflare/dist/utils/cf.js
function injectSessionBinding(manifest, env) {
	if (env["SESSION"]) {
		const sessionConfigOptions = manifest.sessionConfig?.options ?? {};
		Object.assign(sessionConfigOptions, { binding: env[sessionKVBindingName] });
	}
}
//#endregion
//#region node_modules/.pnpm/@astrojs+cloudflare@14.3.3_@types+node@26.6.4_astro@7.3.5_@types+node@26.6.4_jiti@2.7.0_279e0682d3265ea798fa44e48108890d/node_modules/@astrojs/cloudflare/dist/utils/response.js
function applyCloudflareResponseHeaders(response, setCookieHeaders, cacheProviderEnabled) {
	const cookies = [...setCookieHeaders];
	const needsNoStoreDefault = cacheProviderEnabled && !response.headers.has("Cloudflare-CDN-Cache-Control");
	if (cookies.length > 0 || needsNoStoreDefault) {
		const applyHeaders = (target) => {
			for (const cookie of cookies) target.headers.append("Set-Cookie", cookie);
			if (needsNoStoreDefault) target.headers.set("Cloudflare-CDN-Cache-Control", "no-store");
		};
		try {
			applyHeaders(response);
		} catch {
			response = new Response(response.body, response);
			applyHeaders(response);
		}
	}
	return response;
}
var app = createApp();
async function handle(request, env, context) {
	injectSessionBinding(app.manifest, env);
	const staticAsset = matchStaticAsset(app.manifest, request.url, env);
	if (staticAsset) return staticAsset;
	let routeData = void 0;
	if (app.isDev()) {
		const result = await app.devMatch(app.getPathnameFromRequest(request));
		if (result) routeData = result.routeData;
	} else routeData = app.match(request);
	if (!routeData) {
		const asset = await fallbackToAssets(request.url, env);
		if (asset) return asset;
	}
	const locals = createLocals(context);
	const waitUntil = context.waitUntil.bind(context);
	const response = await app.render(request, {
		routeData,
		locals,
		waitUntil,
		prerenderedErrorPageFetch: createErrorPageFetch(env),
		clientAddress: getClientAddress(request)
	});
	return applyCloudflareResponseHeaders(response, app.setCookieHeaders ? [...app.setCookieHeaders(response)] : [], false);
}
//#endregion
//#region \0virtual:cloudflare/worker-entry
var worker_entry_default = { fetch: handle };
//#endregion
export { worker_entry_default as default };
