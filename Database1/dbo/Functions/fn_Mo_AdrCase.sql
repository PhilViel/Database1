
CREATE FUNCTION dbo.fn_Mo_AdrCase
  (@FAddress MoAdress)
RETURNS MoDesc
AS
BEGIN
  DECLARE
    @FAddressStr     MoAdress;

  IF @FAddress IS NULL
    RETURN('')

  --Initialize variables
  SET @FAddressStr  = UPPER(RTRIM(LTRIM(@FAddress)));

  SET @FAddressStr = Replace(@FAddressStr, ' Rue', ' rue');
  SET @FAddressStr = Replace(@FAddressStr, ' Rue.', ' rue');
  SET @FAddressStr = Replace(@FAddressStr, ' Avenue', ' avenue');
  SET @FAddressStr = Replace(@FAddressStr, ' Avenue.', ' avenue');

  SET @FAddressStr = Replace(@FAddressStr, '1E', '1è');
  SET @FAddressStr = Replace(@FAddressStr, '2E', '2è');
  SET @FAddressStr = Replace(@FAddressStr, '3E', '3è');
  SET @FAddressStr = Replace(@FAddressStr, '4E', '4è');
  SET @FAddressStr = Replace(@FAddressStr, '5E', '5è');
  SET @FAddressStr = Replace(@FAddressStr, '6E', '6è');
  SET @FAddressStr = Replace(@FAddressStr, '7E', '7è');
  SET @FAddressStr = Replace(@FAddressStr, '8E', '8è');
  SET @FAddressStr = Replace(@FAddressStr, '9E', '9è');
  SET @FAddressStr = Replace(@FAddressStr, '0E', '0è');

  SET @FAddressStr = Replace(@FAddressStr, '1È', '1è');
  SET @FAddressStr = Replace(@FAddressStr, '2È', '2è');
  SET @FAddressStr = Replace(@FAddressStr, '3È', '3è');
  SET @FAddressStr = Replace(@FAddressStr, '4È', '4è');
  SET @FAddressStr = Replace(@FAddressStr, '5È', '5è');
  SET @FAddressStr = Replace(@FAddressStr, '6È', '6è');
  SET @FAddressStr = Replace(@FAddressStr, '7È', '7è');
  SET @FAddressStr = Replace(@FAddressStr, '8È', '8è');
  SET @FAddressStr = Replace(@FAddressStr, '9È', '9è');
  SET @FAddressStr = Replace(@FAddressStr, '0È', '0è');

  SET @FAddressStr = Replace(@FAddressStr, '1I', '1i');
  SET @FAddressStr = Replace(@FAddressStr, '2I', '2i');
  SET @FAddressStr = Replace(@FAddressStr, '3I', '3i');
  SET @FAddressStr = Replace(@FAddressStr, '4I', '4i');
  SET @FAddressStr = Replace(@FAddressStr, '5I', '5i');
  SET @FAddressStr = Replace(@FAddressStr, '6I', '6i');
  SET @FAddressStr = Replace(@FAddressStr, '7I', '7i');
  SET @FAddressStr = Replace(@FAddressStr, '8I', '8i');
  SET @FAddressStr = Replace(@FAddressStr, '9I', '9i');
  SET @FAddressStr = Replace(@FAddressStr, '0I', '0i');

  SET @FAddressStr = Replace(@FAddressStr, '1St ', '1st ');
  SET @FAddressStr = Replace(@FAddressStr, '2Nd ', '2nd ');
  SET @FAddressStr = Replace(@FAddressStr, '3Th ', '3th ');
  SET @FAddressStr = Replace(@FAddressStr, '4Th ', '4th ');
  SET @FAddressStr = Replace(@FAddressStr, '5Th ', '5th ');
  SET @FAddressStr = Replace(@FAddressStr, '6Th ', '6th ');
  SET @FAddressStr = Replace(@FAddressStr, '7Th ', '7th ');
  SET @FAddressStr = Replace(@FAddressStr, '8Th ', '8th ');
  SET @FAddressStr = Replace(@FAddressStr, '9Th ', '9th ');
  SET @FAddressStr = Replace(@FAddressStr, '0Th ', '0th ');

  SET @FAddressStr = Replace(@FAddressStr, ' Des ', ' des ');
  SET @FAddressStr = Replace(@FAddressStr, '-Des-', '-des-');

  SET @FAddressStr = Replace(@FAddressStr, ' Les ', ' les ');
  SET @FAddressStr = Replace(@FAddressStr, '-Les-', '-les-');

  SET @FAddressStr = Replace(@FAddressStr, ' Du ', ' du ');
  SET @FAddressStr = Replace(@FAddressStr, '-Du-', '-du-');

  SET @FAddressStr = Replace(@FAddressStr, ' De ', ' de ');
  SET @FAddressStr = Replace(@FAddressStr, '-De-', '-de-');

  SET @FAddressStr = Replace(@FAddressStr, ' Le ', ' le ');
  SET @FAddressStr = Replace(@FAddressStr, '-Le-', '-le-');

  SET @FAddressStr = Replace(@FAddressStr, ' La ', ' la ');
  SET @FAddressStr = Replace(@FAddressStr, '-La-', '-la-');

  SET @FAddressStr = Replace(@FAddressStr, ' Aux ', ' aux ');
  SET @FAddressStr = Replace(@FAddressStr, '-Aux-', '-aux-');

  SET @FAddressStr = Replace(@FAddressStr, ' Et ', ' et ');
  SET @FAddressStr = Replace(@FAddressStr, '-Et-', '-et-');

  SET @FAddressStr = Replace(@FAddressStr, ' L''', ' l''');
  SET @FAddressStr = Replace(@FAddressStr, ' D''', ' d''');

  SET @FAddressStr = Replace(@FAddressStr, ' Lac ', ' lac ');

  SET @FAddressStr = Replace(@FAddressStr, ' Chemin ', ' chemin ');
  SET @FAddressStr = Replace(@FAddressStr, ' Ch ', ' ch ');
  SET @FAddressStr = Replace(@FAddressStr, ' Ch. ', ' ch. ');

  SET @FAddressStr = Replace(@FAddressStr, ' Côte ', ' côte ');
  SET @FAddressStr = Replace(@FAddressStr, ' Cote ', ' côte ');

  SET @FAddressStr = Replace(@FAddressStr, ' Route', ' route');
  SET @FAddressStr = Replace(@FAddressStr, ' Rte ', ' route ');

  SET @FAddressStr = Replace(@FAddressStr, ' Rue ', ' rue ');
  SET @FAddressStr = Replace(@FAddressStr, ' Rang ', ' rang ');

  SET @FAddressStr = Replace(@FAddressStr, ' Avenue', ' avenue');
  SET @FAddressStr = Replace(@FAddressStr, ' Ave ', ' ave ');

  SET @FAddressStr = Replace(@FAddressStr, ' Ap ', ' app.');
  SET @FAddressStr = Replace(@FAddressStr, ' Ap. ', ' app.');
  SET @FAddressStr = Replace(@FAddressStr, ' App ', ' app.');
  SET @FAddressStr = Replace(@FAddressStr, ' App. ', ' app.');
  SET @FAddressStr = Replace(@FAddressStr, ' Apt. ', ' apt.');
  SET @FAddressStr = Replace(@FAddressStr, ' Ap.', ' app.');
  SET @FAddressStr = Replace(@FAddressStr, ' App.', ' app.');
  SET @FAddressStr = Replace(@FAddressStr, ' Apt.', ' apt.');

  SET @FAddressStr = Replace(@FAddressStr, ' Place ', ' place ');

  SET @FAddressStr = Replace(@FAddressStr, ' Boul ', ' boul ');
  SET @FAddressStr = Replace(@FAddressStr, ' Boul. ', ' boul. ');
  SET @FAddressStr = Replace(@FAddressStr, ' Bd ', ' boul. ');

  SET @FAddressStr = Replace(@FAddressStr, ' Rr ', ' R.R.');
  SET @FAddressStr = Replace(@FAddressStr, ' Rr. ', ' R.R.');
  SET @FAddressStr = Replace(@FAddressStr, ' R.R. ', ' R.R.');
  SET @FAddressStr = Replace(@FAddressStr, ' Rr.', ' R.R.');

  SET @FAddressStr = Replace(@FAddressStr, ' Bp', ' B.P.');
  SET @FAddressStr = Replace(@FAddressStr, ' Boite ', ' boite ');
  SET @FAddressStr = Replace(@FAddressStr, ' Boîte ', ' boite ');

  SET @FAddressStr = Replace(@FAddressStr, ' Site ', ' site ');

  SET @FAddressStr = Replace(@FAddressStr, ' Cp', ' C.P.');
  SET @FAddressStr = Replace(@FAddressStr, ' C.P. ', ' C.P.');

  SET @FAddressStr = Replace(@FAddressStr, ' Pq ', ' PQ ');
  SET @FAddressStr = Replace(@FAddressStr, ' Qc ', ' QC ');
  SET @FAddressStr = Replace(@FAddressStr, ' Nb ', ' NB ');
  SET @FAddressStr = Replace(@FAddressStr, ' On ', ' ON ');
  SET @FAddressStr = Replace(@FAddressStr, ' Ab ', ' AB ');
  SET @FAddressStr = Replace(@FAddressStr, ' Sk ', ' SK ');
  SET @FAddressStr = Replace(@FAddressStr, ' Nf ', ' NF ');
  SET @FAddressStr = Replace(@FAddressStr, ' Ns ', ' NS ');
  SET @FAddressStr = Replace(@FAddressStr, ' Po ', ' PO ');
  SET @FAddressStr = Replace(@FAddressStr, ' Ma ', ' MA ');
  SET @FAddressStr = Replace(@FAddressStr, ' Usa ', ' USA ');

  if CHARINDEX('Â', @FAddressStr) >= 1
    SET @FAddressStr = Replace(@FAddressStr, 'Â', 'â');
  if CHARINDEX('È', @FAddressStr) >= 1
    SET @FAddressStr = Replace(@FAddressStr, 'È', 'è');
  if CHARINDEX('É', @FAddressStr) >= 1
    SET @FAddressStr = Replace(@FAddressStr, 'É', 'é');
  if CHARINDEX('Ë', @FAddressStr) >= 1
    SET @FAddressStr = Replace(@FAddressStr, 'Ë', 'ë');
  if CHARINDEX('Ê', @FAddressStr) >= 1
    SET @FAddressStr = Replace(@FAddressStr, 'Ê', 'ê');
  if CHARINDEX('Û', @FAddressStr) >= 1
    SET @FAddressStr = Replace(@FAddressStr, 'Û', 'û');
  if CHARINDEX('Ü', @FAddressStr) >= 1
    SET @FAddressStr = Replace(@FAddressStr, 'Ü', 'ü');
  if CHARINDEX('Ï', @FAddressStr) >= 1
    SET @FAddressStr = Replace(@FAddressStr, 'Ï', 'ï');
  if CHARINDEX('Î', @FAddressStr) >= 1
    SET @FAddressStr = Replace(@FAddressStr, 'Î', 'î');
  if CHARINDEX('Ö', @FAddressStr) >= 1
    SET @FAddressStr = Replace(@FAddressStr, 'Ö', 'ö');
  if CHARINDEX('Ô', @FAddressStr) >= 1
    SET @FAddressStr = Replace(@FAddressStr, 'Ô', 'ô');
  if CHARINDEX('Ç', @FAddressStr) >= 1
    SET @FAddressStr = Replace(@FAddressStr, 'Ç', 'ç');

  SET @FAddressStr = Replace(@FAddressStr, '.-', '.');
  SET @FAddressStr = Replace(@FAddressStr, '# ', '#');
  SET @FAddressStr = Replace(@FAddressStr, '  ', ' ');
  SET @FAddressStr = Replace(@FAddressStr, ' è', ' È');
  SET @FAddressStr = Replace(@FAddressStr, '-è', '-È');
  SET @FAddressStr = Replace(@FAddressStr, ' é', ' É');
  SET @FAddressStr = Replace(@FAddressStr, '-é', '-É');
  SET @FAddressStr = Replace(@FAddressStr, '-À', '-à');

  RETURN(@FAddressStr)
END

