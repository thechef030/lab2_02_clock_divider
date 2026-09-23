`timescale 1ns/1ps

module tb_clock_divider;

reg clk=0, rst=1;
integer checks=0;

always #5 clk=~clk;

task step;
begin
    @(posedge clk);
    #1;
end
endtask

task check(
    input condition,
    input [8*100-1:0] description
);
begin
    checks=checks+1;

    if (condition !== 1'b1) begin
        $display(
            "LAB2_FAIL %0s time=%0t",
            description,
            $time
        );
        $fatal(1, "check failed");
    end
end
endtask

task finish;
begin
    $display(
        "LAB2_PASS clock_divider checks=%0d",
        checks
    );
    $finish;
end
endtask

initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_clock_divider);
end

initial begin
    #100000;
    $fatal(1, "watchdog timeout");
end

wire divided, tick, div2, tick2;

clock_divider #(.DIVISOR(10))
    dut(clk, rst, divided, tick);

clock_divider #(.DIVISOR(2))
    minimum(clk, rst, div2, tick2);

integer i, pulses=0;

always @(posedge clk)
    if (!rst && tick)
        pulses = pulses+1;

initial begin

    step;
    check(
        {divided,tick,div2,tick2}===4'b0000,
        "reset"
    );

    rst=0;

    for(i=1;i<=30;i=i+1) begin
        step;

        check(
            divided===((i%10)>=5),
            "divide 10 duty and phase"
        );

        check(
            tick===((i%10)==9),
            "tick before consuming edge"
        );

        check(
            div2===((i%2)==1),
            "minimum divisor duty"
        );

        check(
            tick2===((i%2)==1),
            "minimum tick"
        );
    end

    check(
        pulses===3,
        "three consumed enables in 30 clocks"
    );

    repeat(7)
        step;

    rst=1;
    #1;

    check(
        tick===0,
        "reset masks tick before edge"
    );

    step;

    check(
        divided===0,
        "reset mid period"
    );

    rst=0;

    repeat(4) begin
        step;
        check(
            divided===0,
            "restart low half"
        );
    end

    step;

    check(
        divided===1,
        "restart first transition"
    );

    finish;

end

endmodule
