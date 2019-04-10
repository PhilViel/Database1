create FUNCTION [dbo].WordWrap
(
    @WrapAt int,
    @Text nvarchar(1024)
)
RETURNS nvarchar(1024)
AS
BEGIN
    declare @ReturnVaue nvarchar(1024);--the string to be passed back
    declare @Snip int;-- the length to snip to the last space before the wrapap value
    declare @Block int;-- the block number of the piece in the return string
    set @Block=1;-- initialise the block number
    set @Text=ltrim(rtrim(@Text));-- clean up the input string
    while charindex('  ',@Text)>0 begin -- if there are any double spaces
        set @Text=REPLACE(@Text,'  ',' '); -- replace them with single spaces
    end
    if (@Text is null or DATALENGTH(@Text)<=@WrapAt) begin -- if the input string is null or short enough for 1 block
        set @ReturnVaue='<1>'+@Text+'</1>';-- load it into the return value and we're done
    end else begin -- otherwise we have some work to do
        set @ReturnVaue='' -- so let's initialise the return value
        while DATALENGTH(@Text)>0 begin -- and keep going until we have finished
            -- if the character after the wrapat is a space or there is a space anywhere before the wrapat
            if SUBSTRING(@Text,@WrapAt+1,1)=' ' or CHARINDEX(' ',left(@Text,@WrapAt))>0 begin
                if SUBSTRING(@Text,@WrapAt+1,1)=' ' begin -- if the character after the wrapat is a space
                    set @Snip=@WrapAt-- we can snip to the wrapat
                end else begin
                    --otherwise we have to snip to the last space before the wrapat
                    set @Snip=@WrapAt-charindex(' ',reverse(left(@text,@WrapAt)));
                end
                -- now we can load the return value with snipped text as the current block
                set @ReturnVaue+='<'+CONVERT(varchar,@Block)+'>'+left(@Text,@Snip)+'</'+CONVERT(varchar,@Block)+'>';
                -- and leave just what's left to process, by jumping past the space (@Snip+2)
                set @Text=SUBSTRING(@Text,@Snip+2,1024);
            end else begin-- otherwise we have no space to split to - so we can only cut the string at wrapat
                -- so we load the return value with the left hand wrapat characters as the current block
                set @ReturnVaue+='<'+CONVERT(varchar,@Block)+'>'+LEFT(@Text,@WrapAt)+'</'+CONVERT(varchar,@Block)+'>';
                -- and leave just what's left to process, by jumping past the wrapat (@WrapAp+1)
                set @Text=SUBSTRING(@Text,@WrapAt+1,1024);
            end
        set @Block+=1-- increment the block number in case we still have more work to do
        end
    end
    RETURN @ReturnVaue;
END
