import {Controller} from "@hotwired/stimulus";
import {FrameElement} from "@hotwired/turbo";

export default class extends Controller {
    static targets = ['finished', 'poll', 'frame'];

    declare readonly frameTarget: FrameElement;

    interval?: ReturnType<typeof setInterval>;

    pollTargetConnected() {
        if (this.interval === undefined) {
            this.interval = setInterval(() => {
                this.frameTarget.src = this.frameTarget.src.split('?')[0];
                this.frameTarget.reload();
            }, 10000);
        }
    }

    finishedTargetConnected() {
        if (this.interval !== undefined) {
            clearInterval(this.interval);
            this.interval = undefined;
        }
    }
}