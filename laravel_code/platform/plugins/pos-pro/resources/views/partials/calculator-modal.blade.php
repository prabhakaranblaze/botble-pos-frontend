<x-core::modal
    id="calculator-modal"
    size="sm"
    :title="trans('plugins/pos-pro::pos.calculator')"
    :static-backdrop="false"
    body-class="p-0"
>
    <div class="macos-calculator">
        <!-- Display -->
        <div class="calc-display">
            <div id="calculator-display" class="calc-display-text">0</div>
        </div>

        <!-- Keypad -->
        <div class="calc-keypad">
            <!-- Row 1: AC, +/-, %, ÷ -->
            <div class="calc-row">
                <button type="button" class="calc-btn calc-fn" data-calc="clear">AC</button>
                <button type="button" class="calc-btn calc-fn" data-calc="negate">+/−</button>
                <button type="button" class="calc-btn calc-fn" data-calc="percent">%</button>
                <button type="button" class="calc-btn calc-op" data-calc="op" data-op="/">÷</button>
            </div>

            <!-- Row 2: 7, 8, 9, × -->
            <div class="calc-row">
                <button type="button" class="calc-btn calc-num" data-calc="num" data-num="7">7</button>
                <button type="button" class="calc-btn calc-num" data-calc="num" data-num="8">8</button>
                <button type="button" class="calc-btn calc-num" data-calc="num" data-num="9">9</button>
                <button type="button" class="calc-btn calc-op" data-calc="op" data-op="*">×</button>
            </div>

            <!-- Row 3: 4, 5, 6, − -->
            <div class="calc-row">
                <button type="button" class="calc-btn calc-num" data-calc="num" data-num="4">4</button>
                <button type="button" class="calc-btn calc-num" data-calc="num" data-num="5">5</button>
                <button type="button" class="calc-btn calc-num" data-calc="num" data-num="6">6</button>
                <button type="button" class="calc-btn calc-op" data-calc="op" data-op="-">−</button>
            </div>

            <!-- Row 4: 1, 2, 3, + -->
            <div class="calc-row">
                <button type="button" class="calc-btn calc-num" data-calc="num" data-num="1">1</button>
                <button type="button" class="calc-btn calc-num" data-calc="num" data-num="2">2</button>
                <button type="button" class="calc-btn calc-num" data-calc="num" data-num="3">3</button>
                <button type="button" class="calc-btn calc-op" data-calc="op" data-op="+">+</button>
            </div>

            <!-- Row 5: 0 (wide), ., = -->
            <div class="calc-row">
                <button type="button" class="calc-btn calc-num calc-zero" data-calc="num" data-num="0">0</button>
                <button type="button" class="calc-btn calc-num" data-calc="num" data-num=".">.</button>
                <button type="button" class="calc-btn calc-op" data-calc="equals">=</button>
            </div>
        </div>
    </div>
</x-core::modal>
