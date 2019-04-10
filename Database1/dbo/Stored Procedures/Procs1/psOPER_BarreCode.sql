CREATE procedure dbo.psOPER_BarreCode 

-- exec psOPER_BarreCode 'X-20130110001',664801

	(
	@conventionno varchar(20),
	@HumanID int
	) 

as
BEGIN

	if not exists(
	select 1
	FROM dbo.Un_Convention c
	WHERE SubscriberID = @HumanID
		)
	AND not exists(
	select 1
	FROM dbo.Un_Convention c
	WHERE BeneficiaryID = @HumanID
		)
	begin
	select 0
	return
	end
	
	SELECT 1
	
end

